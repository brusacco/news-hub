# frozen_string_literal: true

module RawgServices
  class ImportGenreDetails < ApplicationService
    include RawgServices::RetryableGenreDetailsRequest

    API_URL = 'https://api.rawg.io/api/genres/%<rawg_id>s'
    DEFAULT_BATCH_SIZE = 100
    DEFAULT_MAX_RETRIES = 3
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    def initialize(api_key:, scope: Genre.all, **options)
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
      total_genres = @scope.count
      processed_genres = 0

      @scope.find_each(batch_size:) do |genre|
        processed_genres += 1
        import_genre_details(genre)
        imported_count += 1
        report_progress(processed_genres, total_genres, genre)
      end

      handle_success(imported_count)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def batch_size
      @batch_size.positive? ? @batch_size : DEFAULT_BATCH_SIZE
    end

    def fetch_genre_details(rawg_id)
      @http_client.get(format(API_URL, rawg_id:), query: { key: @api_key })
    end

    def import_genre_details(genre)
      response = fetch_genre_with_retry(genre)
      genre_data = response.parsed_response

      genre.update!(
        name: genre_data['name'],
        slug: genre_data['slug'],
        description: genre_data['description'],
        games_count: genre_data['games_count'],
        image_background: genre_data['image_background'],
        raw_data: genre_data
      )
    end

    def validate_response!(response, genre)
      return if response.success?

      raise "RAWG genre details request failed with status #{response.code} for genre #{genre.rawg_id}"
    end

    def report_progress(processed_genres, total_genres, genre)
      return if @io.nil?

      @io.puts("[#{processed_genres}/#{total_genres}] #{genre.slug}: details imported")
    end
  end
end
