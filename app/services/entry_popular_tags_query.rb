# frozen_string_literal: true

class EntryPopularTagsQuery < ApplicationService
  def initialize(limit: 5)
    @limit = limit
  end

  def call
    Rails.cache.fetch("popular_tags_#{@limit}", expires_in: 1.hour) do
      Entry.tag_counts_on(:tags).limit(@limit).to_a
    end
  end
end
