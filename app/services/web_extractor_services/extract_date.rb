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
      elsif @doc.at_css('.when') && @date.nil?
        @date = @doc.at_css('.when')
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
  end
end
