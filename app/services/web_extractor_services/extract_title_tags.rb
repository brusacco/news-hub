# frozen_string_literal: true

module WebExtractorServices
  class ExtractTitleTags < ApplicationService
    def initialize(entry, tag_id = nil, tags: nil, compiled_tags: nil)
      @entry = entry
      @tag_id = tag_id
      @tags = tags
      @compiled_tags = compiled_tags
    end

    def call
      entry = load_entry
      tags_found = TagMatcher.call(entry.title, tags:, compiled_tags: @compiled_tags)

      if tags_found.empty?
        handle_error('No tags found')
      else
        handle_success(tags_found)
      end
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def load_entry
      @entry.is_a?(Entry) ? @entry : Entry.find(@entry)
    end

    def tags
      @tags || (@tag_id.nil? ? Tag.all : Tag.where(id: @tag_id))
    end
  end
end
