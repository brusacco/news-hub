# frozen_string_literal: true

require 'test_helper'

module WebExtractorServices
  class ExtractTagsTest < ActiveSupport::TestCase
    setup do
      @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    end

    test 'finds tags in normal entry fields when ai fields are blank' do
      tag = Tag.create!(name: 'Metroid Prime')
      entry = create_entry(title: 'Metroid Prime 4 gets a new trailer', ai_title: nil, ai_description: nil)

      result = ExtractTags.call(entry.id)

      assert result.success?
      assert_equal [tag.name], result.data
    end

    test 'matches tag variations case-insensitively and escapes regex characters' do
      tag = Tag.create!(name: 'Pokemon Legends: Z-A', variations: 'Pokémon Legends Z-A, Pokemon Legends Z.A')
      entry = create_entry(description: 'The latest POKEMON LEGENDS Z.A preview focuses on Lumiose City.')

      result = ExtractTags.call(entry.id)

      assert result.success?
      assert_equal [tag.name], result.data
    end

    test 'can limit matching to one tag' do
      matching_tag = Tag.create!(name: 'Zelda')
      Tag.create!(name: 'Metroid')
      entry = create_entry(title: 'Metroid and Zelda headlines')

      result = ExtractTags.call(entry.id, matching_tag.id)

      assert result.success?
      assert_equal [matching_tag.name], result.data
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
