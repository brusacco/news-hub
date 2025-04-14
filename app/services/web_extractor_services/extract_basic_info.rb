# frozen_string_literal: true

module WebExtractorServices
  class ExtractBasicInfo < ApplicationService
    def initialize(doc)
      @doc = doc
    end

    #-------------------------------------------------------------
    def call
      title = extract_title.truncate(250)
      description = extract_description
      image_url = extract_image_url

      result = { title: title, description: description, image_url: image_url }
      handle_success(result)
    end

    #-------------------------------------------------------------
    # Extract title from pages
    #-------------------------------------------------------------
    def extract_title
      if @doc.at('meta[property="og:title"]')
        @doc.at('meta[property="og:title"]')[:content]
      elsif @doc.title && title.blank?
        @doc.title
      else
        ''
      end
    end

    #-------------------------------------------------------------
    # Extract description from pages
    #-------------------------------------------------------------
    def extract_description
      if @doc.at('meta[property="og:description"]')
        @doc.at('meta[property="og:description"]')[:content]&.strip
      elsif @doc.at('meta[name="description"]')
        @doc.at('meta[name="description"]')[:content]&.strip
      else
        ''
      end
    end

    #-------------------------------------------------------------
    # Extract image url from pages
    #-------------------------------------------------------------
    def extract_image_url
      @doc.at('meta[property="og:image"]')[:content] if @doc.at('meta[property="og:image"]')
    end
  end
end
