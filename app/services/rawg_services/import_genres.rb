# frozen_string_literal: true

module RawgServices
  class ImportGenres < ApplicationService
    API_URL = 'https://api.rawg.io/api/genres'
    DEFAULT_PAGE_SIZE = 40

    def initialize(api_key:, pages: nil, page_size: DEFAULT_PAGE_SIZE, http_client: HTTParty)
      @api_key = api_key.to_s
      @pages = pages.presence&.to_i
      @page_size = page_size.to_i
      @http_client = http_client
    end

    def call
      return handle_error('RAWG_API_KEY is required') if @api_key.blank?

      handle_success(import_pages)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def max_pages
      @pages&.positive? ? @pages : nil
    end

    def page_size
      @page_size.positive? ? @page_size : DEFAULT_PAGE_SIZE
    end

    def fetch_page(page)
      @http_client.get(
        API_URL,
        query: {
          key: @api_key,
          page: page,
          page_size: page_size
        }
      )
    end

    def import_pages
      imported_count = 0
      page = 1

      loop do
        response = fetch_page(page)
        raise "RAWG genres request failed with status #{response.code}" unless response.success?

        imported_count += import_genres(Array(response.parsed_response['results']))
        break if response.parsed_response['next'].blank?
        break if max_pages.present? && page >= max_pages

        page += 1
      end

      imported_count
    end

    def import_genres(genres)
      genres.sum do |genre_data|
        import_genre(genre_data)
        1
      end
    end

    def import_genre(genre_data)
      Genre.find_or_initialize_by(rawg_id: genre_data.fetch('id')).tap do |genre|
        genre.assign_attributes(
          name: genre_data['name'],
          slug: genre_data['slug'],
          games_count: genre_data['games_count'],
          image_background: genre_data['image_background'],
          raw_data: genre_data
        )
        genre.save!
      end
    end
  end
end
