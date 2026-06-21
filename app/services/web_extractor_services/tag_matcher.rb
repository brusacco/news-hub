# frozen_string_literal: true

module WebExtractorServices
  class TagMatcher < ApplicationService
    def initialize(content, tags: Tag.all)
      @content = content.to_s
      @tags = tags
    end

    def call
      @tags.each_with_object([]) do |tag, tags_found|
        next unless TagSanitizer.allowed?(tag.name)

        tags_found << TagSanitizer.normalize(tag.name) if matches?(tag)
      end.uniq
    end

    private

    def matches?(tag)
      terms_for(tag).any? { |term| @content.match?(term_pattern(term)) }
    end

    def terms_for(tag)
      [tag.name, tag.variations.to_s.split(',')].flatten.map(&:strip).compact_blank
    end

    def term_pattern(term)
      /(^|[^\p{Alnum}_])#{Regexp.escape(term)}(?=$|[^\p{Alnum}_])/i
    end
  end
end
