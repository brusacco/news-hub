# frozen_string_literal: true

class EntriesController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  MAX_RELATED_ENTRIES = 6
  INDEX_LIMIT = 60
  TAG_BLACKLIST = %w[Nintendo Nintendo\ Switch Switch Nintendo\ Switch\ 2 Switch\ 2 2025].freeze

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
    set_entry_meta_tags
  end

  private

  def find_related_entries
    main_tags = @entry.tags.pluck(:name) - TAG_BLACKLIST
    entries = Entry.a_week_ago
                   .tagged_with(main_tags, any: true)
                   .where.not(id: @entry.id)
                   .recent
                   .limit(MAX_RELATED_ENTRIES)

    entries.presence || Entry.a_week_ago
                             .tagged_with(@entry.tags.pluck(:name), any: true)
                             .where.not(id: @entry.id)
                             .recent
                             .limit(MAX_RELATED_ENTRIES)
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
    tag_names = @entry.tags.pluck(:name)
    keywords_array = []

    # Add original keywords if available
    if @entry.final_keywords.present?
      keywords_array += @entry.final_keywords.split(',').map(&:strip)
    end

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
