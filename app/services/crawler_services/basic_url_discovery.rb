# frozen_string_literal: true

module CrawlerServices
  class BasicUrlDiscovery < ApplicationService
    require 'httparty'
    require 'nokogiri'

    def initialize(url, validation_options = {})
      @url = url
      @validation_options = validation_options
    end

    def call
      level_one_urls = discover_urls(@url)
      # level_two_urls = level_one_urls.flat_map { |url| discover_urls(url) }.uniq

      valid_urls = validate_urls(level_one_urls)
      handle_success(valid_urls)
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def discover_urls(url)
      response = HTTParty.get(url)
      return [] unless response.success?

      extract_urls(response.body, url)
    end

    def extract_urls(html, base_url)
      document = Nokogiri::HTML(html)
      document.css('a[href]').map do |link|
        href = link['href']
        begin
          URI.join(base_url, href).to_s
        rescue StandardError
          nil
        end
      end.compact.uniq
    end

    def validate_urls(urls)
      urls.select do |url|
        valid_base_url?(url) && valid_article?(url)
      end
    end

    def valid_base_url?(url)
      URI.parse(url).host == URI.parse(@url).host
    rescue URI::InvalidURIError
      false
    end

    def valid_article?(url)
      response = HTTParty.get(url)
      return false unless response.success?

      document = Nokogiri::HTML(response.body)
      meta_tag = document.at_css('meta[property="og:type"][content="article"]')
      meta_tag.present?
    rescue StandardError
      false
    end

    def handle_success(urls)
      # Implement success handling logic (e.g., logging or returning the URLs)
      urls
    end

    def handle_error(error_message)
      # Implement error handling logic (e.g., logging or raising an exception)
      raise error_message
    end
  end
end
