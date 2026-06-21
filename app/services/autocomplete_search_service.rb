# frozen_string_literal: true

class AutocompleteSearchService
  MIN_QUERY_LENGTH = 2
  MAX_RESULTS = 5
  NINTENDO_SITE_ID = 11
  NINTENDO_FALLBACK_IMAGE_URL = 'https://assets.nintendo.com/image/upload/v1643742733/ncom/global/social-share.jpg'

  def initialize(query)
    @query = query.to_s.strip.downcase
  end

  def call
    return empty_results unless valid_query?

    {
      tags: search_tags,
      entries: search_entries
    }
  end

  private

  def valid_query?
    @query.present? && @query.length >= MIN_QUERY_LENGTH
  end

  def empty_results
    { tags: [], entries: [] }
  end

  def search_tags
    Tag.where('LOWER(name) LIKE ?', "%#{@query}%")
       .order(taggings_count: :desc)
       .limit(MAX_RESULTS)
       .map { |tag| serialize_tag(tag) }
  end

  def search_entries
    entry_ids = Entry.matching_text(@query).pluck(:id)

    matching_tags = Tag.where('LOWER(name) LIKE ?', "%#{@query}%")
    entry_ids += Entry.tagged_with(matching_tags.pluck(:name), any: true).pluck(:id) if matching_tags.any?

    Entry.where(id: entry_ids.uniq)
         .order(published_at: :desc)
         .limit(MAX_RESULTS)
         .map { |entry| serialize_entry(entry) }
  end

  def serialize_tag(tag)
    {
      id: tag.id,
      name: tag.name,
      url: Rails.application.routes.url_helpers.tag_path(tag),
      count: tag.taggings_count || 0
    }
  end

  def serialize_entry(entry)
    {
      id: entry.id,
      title: entry.final_title,
      url: Rails.application.routes.url_helpers.entry_path(entry),
      published_at: entry.published_at&.strftime('%b %d, %Y'),
      image_url: resolved_image_url(entry),
      site_id: entry.site_id
    }
  end

  def resolved_image_url(entry)
    return NINTENDO_FALLBACK_IMAGE_URL if entry.site_id == NINTENDO_SITE_ID
    return NINTENDO_FALLBACK_IMAGE_URL if entry.image_url.blank?

    entry.image_url
  end
end
