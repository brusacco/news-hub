# frozen_string_literal: true

module RawgServices
  class ImportGameScreenshots < ApplicationService
    include RawgServices::RetryableGameScreenshotsRequest

    API_URL = 'https://api.rawg.io/api/games/%<rawg_id>s/screenshots'
    DEFAULT_BATCH_SIZE = 100
    DEFAULT_MAX_RETRIES = 3
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    # rubocop:disable Style/ArgumentsForwarding
    def self.sync_game!(game, api_key:, **options)
      new(
        api_key:,
        scope: Game.where(id: game.id),
        **options
      ).send(:sync_game, game)
    end
    # rubocop:enable Style/ArgumentsForwarding

    def initialize(api_key:, scope: Game.all, **options)
      @api_key = api_key.to_s
      @scope = scope
      @batch_size = options.fetch(:batch_size, DEFAULT_BATCH_SIZE).to_i
      @max_retries = options.fetch(:max_retries, DEFAULT_MAX_RETRIES).to_i
      @http_client = options.fetch(:http_client, HTTParty)
      @replace = options.fetch(:replace, true)
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
        synced_count = sync_game(game)
        imported_count += synced_count
        report_progress(processed_games, total_games, game, synced_count)
      end

      handle_success(imported_count)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def batch_size
      @batch_size.positive? ? @batch_size : DEFAULT_BATCH_SIZE
    end

    def fetch_screenshots(rawg_id)
      @http_client.get(
        format(API_URL, rawg_id: rawg_id),
        query: { key: @api_key }
      )
    end

    def sync_game(game)
      response = fetch_screenshots_with_retry(game)

      screenshots_data = Array(response.parsed_response['results'])
      imported_ids = upsert_screenshots(game, screenshots_data)

      game.screenshots.where.not(rawg_id: imported_ids).delete_all if @replace

      screenshots_data.size
    end

    def validate_response!(response, game)
      return if response.success?

      raise "RAWG screenshots request failed with status #{response.code} for game #{game.rawg_id}"
    end

    def upsert_screenshots(game, screenshots_data)
      screenshots_data.each_with_index.map do |screenshot_data, index|
        upsert_screenshot(game, screenshot_data, index).rawg_id
      end
    end

    def upsert_screenshot(game, screenshot_data, index)
      game.screenshots.find_or_initialize_by(rawg_id: screenshot_data.fetch('id')).tap do |screenshot|
        screenshot.assign_attributes(
          image: screenshot_data['image'],
          width: screenshot_data['width'],
          height: screenshot_data['height'],
          is_deleted: screenshot_data['is_deleted'] || false,
          position: index,
          raw_data: screenshot_data
        )
        screenshot.save!
      end
    end

    def report_progress(processed_games, total_games, game, synced_count)
      return if @io.nil?

      @io.puts("[#{processed_games}/#{total_games}] #{game.slug}: #{synced_count} screenshots")
    end
  end
end
