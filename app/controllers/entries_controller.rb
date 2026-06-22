# frozen_string_literal: true

class EntriesController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  MAX_RELATED_ENTRIES = 6
  INDEX_LIMIT = 60
  TAG_BLACKLIST = ['Nintendo', 'Nintendo Switch', 'Switch', 'Nintendo Switch 2', 'Switch 2', '2025'].freeze

  def index
    entries = Entry.recent.includes(:tags, :site)
    @pagy, @entries = pagy(entries, limit: INDEX_LIMIT)

    set_default_meta_tags(
      title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
      description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles, game updates, and platform announcements.',
      keywords: 'Nintendo news archive, Nintendo updates, Nintendo Switch news, gaming news',
      canonical: entries_url,
      og: {
        title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
        description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles, game updates, and platform announcements.',
        type: 'website',
        url: entries_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
        description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles and platform announcements.'
      }
    )
  end

  def show
    @entry = Entry.with_tags.with_site.friendly.find(params[:id])
    @entries = find_related_entries
    @games = related_games
    set_entry_meta_tags
  end

  private

  def related_games
    @entry.entry_games
          .includes(game: :genres)
          .strongest_first
          .limit(6)
          .map(&:game)
  end

  def find_related_entries
    base_scope = Entry.tagger_scope.where.not(id: @entry.id)
    prioritized_tags = related_tag_groups

    prioritized_tags.each_with_object([]) do |tag_names, entries|
      next if entries.length >= MAX_RELATED_ENTRIES

      entries.concat(related_entries_for(base_scope, tag_names, excluded_ids: entries.map(&:id)).to_a)
    end.first(MAX_RELATED_ENTRIES)
  end

  def related_tag_groups
    title_tags = title_related_tags

    [
      { names: sanitized_tag_names(title_tags) - TAG_BLACKLIST, context: :title_tags }
    ].reject { |group| group[:names].blank? }
  end

  def sanitized_tag_names(tags)
    tags.map { |tag| TagSanitizer.normalize(tag.name) }.compact
  end

  def related_entries_for(scope, tag_group, excluded_ids: [])
    return Entry.none if tag_group[:names].blank?

    tagged_entries = scope.where.not(id: excluded_ids)
                          .tagged_with(tag_group[:names], any: true, on: tag_group[:context])
                          .recent
                          .limit(MAX_RELATED_ENTRIES)
                          .to_a
    remaining = MAX_RELATED_ENTRIES - tagged_entries.length
    return tagged_entries if remaining <= 0

    excluded_ids += tagged_entries.map(&:id)
    tagged_entries + title_matching_entries(scope, tag_group[:names], excluded_ids:, limit: remaining)
  end

  def title_related_tags
    title_tags = @entry.display_title_tags(limit: nil)
    return title_tags if title_tags.any?

    @entry.display_tags(limit: nil).select { |tag| tag_name_in_entry_title?(tag.name) }
  end

  def tag_name_in_entry_title?(tag_name)
    normalized_name = TagSanitizer.normalize(tag_name).to_s

    @entry.final_title.to_s.downcase.include?(normalized_name.downcase)
  end

  def title_matching_entries(scope, tag_names, excluded_ids:, limit:)
    title_conditions = tag_names.map do |tag_name|
      query = "%#{Entry.sanitize_sql_like(tag_name.downcase)}%"
      Entry.arel_table[:title].lower.matches(query).or(Entry.arel_table[:ai_title].lower.matches(query))
    end

    scope.where.not(id: excluded_ids)
         .where(title_conditions.inject(:or))
         .recent
         .limit(limit)
         .to_a
  end

  def set_entry_meta_tags
    title = optimized_title(@entry.final_title)

    # Rich SEO description with context and keywords
    base_description = @entry.final_description || @entry.description || ''
    description = if base_description.present?
                    optimized_description(base_description)
                  else
                    optimized_description(
                      "Read the latest news about #{@entry.final_title}. " \
                      'Stay updated with Nintendo gaming news, updates, and insights on Nintendo News Hub.'
                    )
                  end

    # Enhanced keywords with semantic variations
    tag_names = @entry.display_tags(limit: nil).map { |tag| TagSanitizer.normalize(tag.name) }
    keywords_array = []

    # Add original keywords if available
    keywords_array += @entry.final_keywords.split(',').map(&:strip) if @entry.final_keywords.present?

    # Add tag-based keywords
    tag_names.each do |tag|
      keywords_array << tag
      keywords_array << "#{tag} news"
      keywords_array << "Nintendo #{tag}"
    end

    # Add category-based keywords
    if @entry.category.present?
      keywords_array << @entry.category
      keywords_array << "#{@entry.category} news"
    end

    # Add default Nintendo keywords
    keywords_array += ['Nintendo news', 'gaming news', 'Nintendo Switch', 'Nintendo updates']

    keywords = keywords_array.uniq.join(', ')
    image_url = @entry.image_url.presence || default_image_url

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: keywords,
      canonical: entry_url(@entry),
      og: {
        title: title,
        description: description,
        type: 'article',
        url: entry_url(@entry),
        image: image_url,
        published_time: @entry.published_at&.iso8601,
        author: 'Nintendo News Hub',
        section: @entry.category || 'Gaming News',
        tag: tag_names.join(', ')
      },
      article: {
        published_time: @entry.published_at&.iso8601,
        author: 'Nintendo News Hub',
        section: @entry.category || 'Gaming News',
        tag: tag_names.join(', '),
        expiration_time: nil,
        modified_time: @entry.updated_at&.iso8601
      },
      twitter: {
        card: 'summary_large_image',
        title: title,
        description: description,
        image: image_url,
        creator: '@NintendoNewsHub',
        site: '@NintendoNewsHub'
      }
    )
  end
end
