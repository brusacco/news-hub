# frozen_string_literal: true

module WebExtractorServices
  class ExtractTags < ApplicationService
    def initialize(entry_id, tag_id = nil)
      @entry_id = entry_id
      @tag_id = tag_id
    end

    def call
      entry = Entry.find(@entry_id)
      tags_found = TagMatcher.call(searchable_content(entry), tags: tags)

      if tags_found.empty?
        handle_error('No tags found')
      else
        handle_success(tags_found)
      end
    rescue StandardError => e
      handle_error(e.message)
    end

    private

    def searchable_content(entry)
      [
        entry.ai_title,
        entry.ai_description,
        entry.title,
        entry.description,
        entry.ai_summary,
        entry.summary,
        entry.content,
        entry.category,
        entry.entities
      ].compact_blank.join(' ')
    end

    def tags
      @tag_id.nil? ? Tag.all : Tag.where(id: @tag_id)
    end
  end
end
