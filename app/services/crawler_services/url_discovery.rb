# frozen_string_literal: true

module CrawlerServices
  class UrlDiscovery < ApplicationService
    def initialize(url)
      @url = url
    end

    def call
      response = fetch_page(@url)
      return handle_error(response.error) unless response.success?

      urls = extract_urls(response.data)
      handle_success(urls)
    end
  end
end
