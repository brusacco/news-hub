# frozen_string_literal: true

module RawgServices
  class ImportDeveloperDetails < ApplicationService
    include RawgServices::RetryableDeveloperDetailsRequest

    API_URL = 'https://api.rawg.io/api/developers/%<rawg_id>s'
    DEFAULT_BATCH_SIZE = 100
    DEFAULT_MAX_RETRIES = 3
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    def initialize(api_key:, scope: Developer.all, **options)
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
      total_developers = @scope.count
      processed_developers = 0

      @scope.find_each(batch_size:) do |developer|
        processed_developers += 1
        import_developer_details(developer)
        imported_count += 1
        report_progress(processed_developers, total_developers, developer)
      end

      handle_success(imported_count)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def batch_size
      @batch_size.positive? ? @batch_size : DEFAULT_BATCH_SIZE
    end

    def fetch_developer_details(rawg_id)
      @http_client.get(format(API_URL, rawg_id:), query: { key: @api_key })
    end

    def import_developer_details(developer)
      response = fetch_developer_with_retry(developer)
      developer_data = response.parsed_response

      developer.update!(
        name: developer_data['name'],
        slug: developer_data['slug'],
        description: developer_data['description'],
        games_count: developer_data['games_count'],
        image_background: developer_data['image_background'],
        raw_data: developer_data
      )
    end

    def validate_response!(response, developer)
      return if response.success?

      raise "RAWG developer details request failed with status #{response.code} for developer #{developer.rawg_id}"
    end

    def report_progress(processed_developers, total_developers, developer)
      return if @io.nil?

      @io.puts("[#{processed_developers}/#{total_developers}] #{developer.slug}: details imported")
    end
  end
end
