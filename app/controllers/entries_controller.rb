# frozen_string_literal: true

class EntriesController < ApplicationController
  MAX_RELATED_ENTRIES = 6
  def index; end

  def show
    @entry = Entry.friendly.find(params[:id])

    blacklist = ['Nintendo',
                 'Nintendo Switch',
                 'Switch',
                 'Nintendo Switch 2',
                 'Switch 2',
                 '2025']

    @main_tags = @entry.tags.pluck(:name) - blacklist
    @entries = Entry.a_week_ago
                    .tagged_with(@main_tags, any: true)
                    .where.not(id: @entry.id)
                    .order(published_at: :desc).limit(MAX_RELATED_ENTRIES)

    if @entries.empty?
      @entries = Entry.a_week_ago
                      .tagged_with(@entry.tags, any: true)
                      .order(published_at: :desc)
                      .limit(MAX_RELATED_ENTRIES)
    end

    set_meta_tags title: @entry.final_title,
                  description: @entry.final_description,
                  keywords: @entry.final_keywords,
                  canonical: entry_url(@entry),
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: entry_url(@entry),
                    image: @entry.image_url
                  },
                  article: {
                    published_time: @entry.published_at
                  },
                  twitter: { card: 'summary' }
  end
end
