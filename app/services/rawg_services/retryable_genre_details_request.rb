# frozen_string_literal: true

module RawgServices
  module RetryableGenreDetailsRequest
    private

    def fetch_genre_with_retry(genre)
      attempts = 0

      begin
        attempts += 1
        response = fetch_genre_details(genre.rawg_id)
        validate_response!(response, genre)
        response
      rescue StandardError => e
        raise e unless retryable_error?(e, attempts)

        retry_delay = retry_delay_for(attempts)
        report_retry(genre, attempts, retry_delay, e)
        @sleeper.call(retry_delay)
        retry
      end
    end

    def report_retry(genre, attempts, retry_delay, error)
      return if @io.nil?

      @io.puts("Retry #{attempts}/#{max_retries} for genre #{genre.slug} in #{retry_delay}s after #{error.message}")
    end

    def max_retries
      @max_retries.positive? ? @max_retries : ImportGenreDetails::DEFAULT_MAX_RETRIES
    end

    def retryable_error?(error, attempts)
      attempts <= max_retries && retryable_status_error?(error)
    end

    def retryable_status_error?(error)
      status_code = error.message[/status (\d{3})/, 1]&.to_i
      status_code.present? && ImportGenreDetails::RETRYABLE_STATUS_CODES.include?(status_code)
    end

    def retry_delay_for(attempts)
      attempts
    end
  end
end
