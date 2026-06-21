# frozen_string_literal: true

module WebExtractorServices
  class TagMatcher < ApplicationService
    CompiledTag = Struct.new(:name, :pattern, keyword_init: true)

    def self.compile(tags)
      tags.filter_map do |tag|
        next unless TagSanitizer.allowed?(tag.name)

        terms = terms_for(tag)
        next if terms.blank?

        CompiledTag.new(name: TagSanitizer.normalize(tag.name), pattern: pattern_for(terms))
      end
    end

    def self.terms_for(tag)
      [tag.name, tag.variations.to_s.split(',')].flatten.map(&:strip).compact_blank.uniq
    end

    def self.pattern_for(terms)
      escaped_terms = terms.map { |term| Regexp.escape(term) }

      /(^|[^\p{Alnum}_])(?:#{escaped_terms.join('|')})(?=$|[^\p{Alnum}_])/i
    end

    def initialize(content, tags: Tag.all, compiled_tags: nil)
      @content = content.to_s
      @compiled_tags = compiled_tags || self.class.compile(tags)
    end

    def call
      @compiled_tags.each_with_object([]) do |tag, tags_found|
        tags_found << tag.name if matches?(tag)
      end.uniq
    end

    private

    def matches?(tag)
      @content.match?(tag.pattern)
    end
  end
end
