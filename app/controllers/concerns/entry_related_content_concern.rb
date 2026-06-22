# frozen_string_literal: true

module EntryRelatedContentConcern
  extend ActiveSupport::Concern

  MAX_RELATED_ENTRIES = 6
  TAG_BLACKLIST = ['Nintendo', 'Nintendo Switch', 'Switch', 'Nintendo Switch 2', 'Switch 2', '2025'].freeze

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

    tagged_entries = tagged_related_entries(scope, tag_group, excluded_ids)
    remaining = MAX_RELATED_ENTRIES - tagged_entries.length
    return tagged_entries if remaining <= 0

    excluded_ids += tagged_entries.map(&:id)
    tagged_entries + title_matching_entries(scope, tag_group[:names], excluded_ids:, limit: remaining)
  end

  def tagged_related_entries(scope, tag_group, excluded_ids)
    scope.where.not(id: excluded_ids)
         .tagged_with(tag_group[:names], any: true, on: tag_group[:context])
         .recent
         .limit(MAX_RELATED_ENTRIES)
         .to_a
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
    conditions = title_match_conditions(tag_names)

    scope.where.not(id: excluded_ids)
         .where(conditions.inject(:or))
         .recent
         .limit(limit)
         .to_a
  end

  def title_match_conditions(tag_names)
    tag_names.map do |tag_name|
      query = "%#{Entry.sanitize_sql_like(tag_name.downcase)}%"
      Entry.arel_table[:title].lower.matches(query).or(Entry.arel_table[:ai_title].lower.matches(query))
    end
  end
end
