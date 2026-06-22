# frozen_string_literal: true

module RawgServices
  class ImportGameDetails < ApplicationService
    include RawgServices::RetryableGameDetailsRequest

    API_URL = 'https://api.rawg.io/api/games/%<rawg_id>s'
    DEFAULT_BATCH_SIZE = 100
    DEFAULT_MAX_RETRIES = 3
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze
    BASE_ATTRIBUTE_KEYS = %i[
      slug name name_original description metacritic metacritic_platforms released background_image
      background_image_additional website rating rating_top ratings reactions added added_by_status playtime
      platforms
    ].freeze
    COMMUNITY_ATTRIBUTE_KEYS = %i[
      reddit_url reddit_name reddit_description reddit_logo reddit_count twitch_count youtube_count
      reviews_text_count metacritic_url
    ].freeze
    COUNT_ATTRIBUTE_KEYS = %i[
      screenshots_count movies_count creators_count achievements_count parent_achievements_count ratings_count
      suggestions_count parents_count additions_count game_series_count
    ].freeze
    RELATIONSHIP_ATTRIBUTE_KEYS = %i[alternative_names esrb_rating].freeze

    def initialize(api_key:, scope: Game.all, **options)
      @api_key = api_key.to_s
      @scope = scope
      @batch_size = options.fetch(:batch_size, DEFAULT_BATCH_SIZE).to_i
      @max_retries = options.fetch(:max_retries, DEFAULT_MAX_RETRIES).to_i
      @http_client = options.fetch(:http_client, HTTParty)
      @io = options.fetch(:io, $stdout)
      @sleeper = options.fetch(:sleeper, ->(seconds) { sleep(seconds) })
    end

    def call
      return handle_error('RAWG_API_KEY is required') if @api_key.blank?

      imported_count = 0
      total_games = @scope.count
      processed_games = 0

      @scope.find_each(batch_size:) do |game|
        processed_games += 1
        import_game_details(game)
        imported_count += 1
        report_progress(processed_games, total_games, game)
      end

      handle_success(imported_count)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def batch_size
      @batch_size.positive? ? @batch_size : DEFAULT_BATCH_SIZE
    end

    def fetch_details(rawg_id)
      @http_client.get(format(API_URL, rawg_id:), query: { key: @api_key })
    end

    def import_game_details(game)
      response = fetch_details_with_retry(game)

      game_data = response.parsed_response

      game.update!(attributes_for(game_data))
      SyncGameDevelopers.sync_game!(game, game_data['developers'])
    end

    def validate_response!(response, game)
      return if response.success?

      raise "RAWG game details request failed with status #{response.code} for game #{game.rawg_id}"
    end

    def attributes_for(game_data)
      mapped_attributes(game_data, BASE_ATTRIBUTE_KEYS)
        .merge(mapped_attributes(game_data, COMMUNITY_ATTRIBUTE_KEYS))
        .merge(mapped_attributes(game_data, COUNT_ATTRIBUTE_KEYS))
        .merge(mapped_attributes(game_data, RELATIONSHIP_ATTRIBUTE_KEYS))
        .merge(
          tba: game_data['tba'] || false,
          rawg_updated_at: game_data['updated'],
          raw_data: game_data
        )
    end

    def report_progress(processed_games, total_games, game)
      return if @io.nil?

      @io.puts("[#{processed_games}/#{total_games}] #{game.slug}: details imported")
    end

    def mapped_attributes(game_data, keys)
      keys.index_with { |key| game_data[key.to_s] }
    end
  end
end
