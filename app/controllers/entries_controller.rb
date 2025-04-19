# frozen_string_literal: true

class EntriesController < ApplicationController
  def index; end

  def show
    @entry = Entry.friendly.find(params[:id])
    @entries = Entry.tagged_with(@entry.tags, any: true).where.not(id: @entry.id).order(published_at: :desc).limit(6)
    @entries = Entry.where.not(id: @entry.id).order(published_at: :desc).limit(9) unless @entries.any?

    set_meta_tags title: @entry.final_title,
                  description: @entry.final_description,
                  keywords: @entry.final_keywords,
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: entry_url(@entry),
                    image: @entry.image_url
                  },
                  twitter: { card: 'summary' }
  end
end
