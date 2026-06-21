# frozen_string_literal: true

module RawgServices
  class ImportNintendoSwitchGames < ApplicationService
    API_URL = 'https://api.rawg.io/api/games'
    NINTENDO_SWITCH_PLATFORM_ID = 7
    DEFAULT_PAGE_SIZE = 40

    def initialize(api_key:, pages: nil, page_size: DEFAULT_PAGE_SIZE, ordering: '-released', http_client: HTTParty)
      @api_key = api_key.to_s
      @pages = pages.presence&.to_i
      @page_size = page_size.to_i
      @ordering = ordering
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
          platforms: NINTENDO_SWITCH_PLATFORM_ID,
          page: page,
          page_size: page_size,
          ordering: @ordering
        }
      )
    end

    def import_pages
      imported_count = 0
      page = 1

      loop do
        response = fetch_page(page)
        raise "RAWG request failed with status #{response.code}" unless response.success?

        imported_count += import_games(Array(response.parsed_response['results']))
        break if response.parsed_response['next'].blank?
        break if max_pages.present? && page >= max_pages

        page += 1
      end

      imported_count
    end

    def import_games(games)
      games.sum do |game_data|
        import_game(game_data)
        1
      end
    end

    def import_game(game_data)
      Game.find_or_initialize_by(rawg_id: game_data.fetch('id')).tap do |game|
        game.assign_attributes(attributes_for(game_data))
        game.save!
        SyncGameGenres.sync_game!(game, Array(game_data['genres']))
      end
    end

    def attributes_for(game_data)
      {
        name: game_data['name'],
        slug: game_data['slug'],
        released: game_data['released'],
        tba: game_data['tba'] || false,
        background_image: game_data['background_image'],
        rating: game_data['rating'],
        rating_top: game_data['rating_top'],
        ratings_count: game_data['ratings_count'],
        metacritic: game_data['metacritic'],
        playtime: game_data['playtime'],
        rawg_updated_at: game_data['updated'],
        platforms: game_data['platforms'],
        rawg_genres: game_data['genres'],
        stores: game_data['stores'],
        raw_data: game_data
      }
    end
  end
end
