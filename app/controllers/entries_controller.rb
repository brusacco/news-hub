# frozen_string_literal: true

class EntriesController < ApplicationController
  include MetaTagsConcern

  MAX_RELATED_ENTRIES = 6
  TAG_BLACKLIST = %w[Nintendo Nintendo\ Switch Switch Nintendo\ Switch\ 2 Switch\ 2 2025].freeze

  def index; end

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
    description = optimized_description(@entry.final_description, fallback: @entry.description)
    image_url = @entry.image_url.presence || default_image_url

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: @entry.final_keywords || 'Nintendo news, gaming news',
      canonical: entry_url(@entry),
      og: {
        title: title,
        description: description,
        type: 'article',
        url: entry_url(@entry),
        image: image_url
      },
      article: {
        published_time: @entry.published_at&.iso8601,
        modified_time: @entry.updated_at&.iso8601,
        author: 'Nintendo News Hub',
        section: @entry.category || 'Gaming News',
        tag: @entry.tags.pluck(:name).join(', ')
      },
      twitter: {
        card: 'summary_large_image',
        title: title,
        description: description,
        image: image_url
      }
    )
  end
end
