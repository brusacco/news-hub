# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)

    set_meta_tags title: 'Nintendo News Hub',
                  description: 'Best Nintendo News Online',
                  keywords: 'Nintendo, News, Aggregator, Switch, Wii U',
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: root_url
                    # image: view_context.asset_url('images/Rostra-Powertrain-Controls-logo.png')
                  },
                  twitter: { card: 'summary' }
  end

  def trending
    @entries = Entry.a_day_ago.order(total_count: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end

  def who
  end

  def terms
  end

  def privacy
  end

  def search
    @keyword = params[:keyword]
    @entries = if @keyword.present?
                 query = @keyword.downcase

                 # Buscar tags que coincidan
                 matching_tags = Tag.where('LOWER(name) LIKE ?', "%#{query}%")

                 # Obtener IDs de diferentes fuentes
                 entry_ids = []

                 # IDs de entradas por título
                 entry_ids += Entry.where('LOWER(title) LIKE ?', "%#{query}%").pluck(:id)

                 # IDs de entradas por descripción
                 entry_ids += Entry.where('LOWER(description) LIKE ?', "%#{query}%").pluck(:id)

                 # IDs de entradas por tags si hay tags coincidentes
                 entry_ids += Entry.tagged_with(matching_tags.map(&:name), any: true).pluck(:id) if matching_tags.any?

                 # Obtener entradas únicas y ordenarlas
                 Entry.where(id: entry_ids.uniq).order(published_at: :desc)
               else
                 Entry.none
               end

    @pagy, @entries = pagy(@entries, limit: 60)

    set_meta_tags title: "Search results for '#{@keyword}'",
                  description: "Search results for '#{@keyword}' on Nintendo News Hub",
                  keywords: @keyword,
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: search_url(keyword: @keyword)
                  },
                  twitter: { card: 'summary' }
  end

  def search_autocomplete
    query = params[:q].to_s.strip.downcase

    results = {
      tags: [],
      entries: []
    }

    if query.present? && query.length >= 2
      # Buscar tags usando el modelo Tag personalizado que tiene friendly_id
      matching_tags = Tag.where('LOWER(name) LIKE ?', "%#{query}%")
                         .order(taggings_count: :desc)
                         .limit(5)

      results[:tags] = matching_tags.map do |tag|
        {
          id: tag.id,
          name: tag.name,
          url: tag_path(tag),
          count: tag.taggings_count || 0
        }
      end

      # Buscar entradas que coincidan con el término o tengan tags relacionados
      # Obtener IDs de diferentes fuentes
      entry_ids = []

      # IDs de entradas por título
      entry_ids += Entry.where('LOWER(title) LIKE ?', "%#{query}%").pluck(:id)

      # IDs de entradas por descripción
      entry_ids += Entry.where('LOWER(description) LIKE ?', "%#{query}%").pluck(:id)

      # IDs de entradas por tags si hay tags coincidentes
      entry_ids += Entry.tagged_with(matching_tags.map(&:name), any: true).pluck(:id) if matching_tags.any?

      # Obtener entradas únicas y ordenarlas
      entries = Entry.where(id: entry_ids.uniq)
                     .order(published_at: :desc)
                     .limit(5)

      results[:entries] = entries.map do |entry|
        {
          id: entry.id,
          title: entry.final_title,
          url: entry_path(entry),
          published_at: entry.published_at&.strftime('%b %d, %Y'),
          image_url: entry.image_url
        }
      end
    end

    render json: results
  end
end
