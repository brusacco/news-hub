# frozen_string_literal: true

module RawgServices
  module RetryableDeveloperDetailsRequest
    private

    def fetch_developer_with_retry(developer)
      attempts = 0

      begin
        attempts += 1
        response = fetch_developer_details(developer.rawg_id)
        validate_response!(response, developer)
        response
      rescue StandardError => e
        raise e unless retryable_error?(e, attempts)

        retry_delay = retry_delay_for(attempts)
        report_retry(developer, attempts, retry_delay, e)
        @sleeper.call(retry_delay)
        retry
      end
    end

    def report_retry(developer, attempts, retry_delay, error)
      return if @io.nil?

      @io.puts(
        "Retry #{attempts}/#{max_retries} for developer #{developer.slug} in #{retry_delay}s after #{error.message}"
      )
    end

    def max_retries
      @max_retries.positive? ? @max_retries : ImportDeveloperDetails::DEFAULT_MAX_RETRIES
    end

    def retryable_error?(error, attempts)
      attempts <= max_retries && retryable_status_error?(error)
    end

    def retryable_status_error?(error)
      status_code = error.message[/status (\d{3})/, 1]&.to_i
      status_code.present? && ImportDeveloperDetails::RETRYABLE_STATUS_CODES.include?(status_code)
    end

    def retry_delay_for(attempts)
      attempts
    end
  end
end
