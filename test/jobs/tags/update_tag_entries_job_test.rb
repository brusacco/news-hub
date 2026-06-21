# frozen_string_literal: true

require 'test_helper'

module Tags
  class UpdateTagEntriesJobTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    end

    test 'retag scans untagged entries and persists matching taggings' do
      tag = Tag.create!(name: 'Zelda')
      matching_entry = create_entry(title: 'New Zelda update')
      non_matching_entry = create_entry(title: 'Metroid update')

      UpdateTagEntriesJob.perform_now(tag.id)

      assert_includes matching_entry.reload.tag_list, tag.name
      assert_not_includes non_matching_entry.reload.tag_list, tag.name
    end

    private

    def create_entry(attributes = {})
      Entry.create!(
        {
          site: @site,
          title: 'Nintendo story',
          description: 'Nintendo description',
          content: 'Nintendo content',
          source_url: "https://example.com/#{SecureRandom.uuid}",
          published_at: 1.hour.ago
        }.merge(attributes)
      )
    end
  end
end
