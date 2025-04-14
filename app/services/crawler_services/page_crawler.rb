# frozen_string_literal: true

module CrawlerServices
  class PageCrawler < ApplicationService
    def initialize(url)
      @url = url
    end
  end
end
