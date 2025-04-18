# frozen_string_literal: true

require 'open3'

module WebExtractorServices
  class ArticleExtractor < ApplicationService
    def initialize(url, html)
      @url = url
      @html = html
    end

    def call
      script_path = Rails.root.join('lib/readability.js')
      args = [@url]
      if @html
        require 'base64'
        args << Base64.strict_encode64(@html)
      end
      stdout, _stderr, status = Open3.capture3('node', script_path.to_s, *args)
      if status.success?
        begin
          doc = JSON.parse(stdout)
          text_content = doc['textContent']

          result = { content: text_content }
          handle_success(result)
        rescue JSON::ParserError
          handle_error('Invalid JSON output')
        end
      else
        handle_error('Node script failed')
      end
    end
  end
end
