# frozen_string_literal: true

class EntrySearchService
  MIN_QUERY_LENGTH = 2

  def initialize(query)
    @query = query.to_s.strip.downcase
  end

  def call
    return Entry.none if @query.blank? || @query.length < MIN_QUERY_LENGTH

    entry_ids = search_by_text + search_by_tags
    Entry.where(id: entry_ids.uniq).order(published_at: :desc)
  end

  private

  def search_by_text
    Entry.matching_text(@query).pluck(:id)
  end

  def search_by_tags
    matching_tags = Tag.where('LOWER(name) LIKE ?', "%#{@query}%")
    return [] if matching_tags.empty?

    Entry.tagged_with(matching_tags.pluck(:name), any: true).pluck(:id)
  end
end
