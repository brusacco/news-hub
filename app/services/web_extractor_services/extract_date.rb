# frozen_string_literal: true

module WebExtractorServices
  class ExtractDate < ApplicationService
    def initialize(doc)
      @doc = doc
      @date = nil
      @parsed = false
    end

    def call
      if @doc.at('meta[property="article:published_time"]')
        @date = @doc.at('meta[property="article:published_time"]')[:content]
        @parsed = true
      elsif @doc.at('meta[property="article:modified_time"]') && @date.nil?
        @date = @doc.at('meta[property="article:modified_time"]')[:content]
        @parsed = true
      elsif @doc.at('meta[property="og:article:published_time"]') && @date.nil?
        @date = @doc.at('meta[property="og:article:published_time"]')[:content]
        @parsed = true
      elsif @doc.at('script[type="application/ld+json"]') && @date.nil?
        @doc.search('script[type="application/ld+json"]').each do |script|
          ld_json_text = script.text
          @date = date_from_ld(ld_json_text)
          if @date
            @parsed = true
            break # Stop once a valid date is found
          end
        end
      elsif @doc.at_css('.when') && @date.nil?
        date_text = @doc.at_css('.when').text
        @date = date_text.split('am').first if date_text.include?('am')
        @date = date_text.split('pm').first if date_text.include?('pm')
        @parsed = false
      else
        @date = nil
      end

      if @date.nil?
        handle_error('Fecha no encontrada')
      else
        @date = Chronic.parse(@date, endian_precedence: :little) unless @parsed
        handle_success({ published_at: @date })
      end
    end

    private

    #------------------------------------------------------------------------------------
    # Parse ld+json data
    #------------------------------------------------------------------------------------
    def date_from_ld(json_ld)
      data = JSON.parse(json_ld)
      find_key(data, 'datePublished')
    end

    #------------------------------------------------------------------------------------
    # Fins a key in a JSON structure at any level
    #------------------------------------------------------------------------------------
    def find_key(data, key)
      case data
      when Array
        data.each do |item|
          result = find_key(item, key)
          return result if result
        end
      when Hash
        return data[key] if data.key?(key)

        data.each_value do |value|
          result = find_key(value, key)
          return result if result
        end
      end
      nil
    end
  end
end
