# frozen_string_literal: true

class FetchSiteUrlsJob < ApplicationJob
  queue_as :default

  def perform(site_id)
    site = Site.find(site_id)
    return unless site.url

    # Use BasicUrlDiscovery to fetch URLs
    url_discovery_service = CrawlerServices::BasicUrlDiscovery.new(site.url)
    discovered_urls = url_discovery_service.call

    # Handle the discovered URLs (e.g., log them or save them to the database)
    handle_discovered_urls(site, discovered_urls)
  rescue StandardError => e
    Rails.logger.error("Failed to fetch URLs for site ##{site_id}: #{e.message}")
  end

  private

  def handle_discovered_urls(site, urls)
    # Example: Log the discovered URLs
    urls.each do |url|
      Rails.logger.info("Discovered URL for site ##{site.id}: #{url}")
    end
  end
end
