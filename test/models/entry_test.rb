# frozen_string_literal: true

require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'requires published_at to be present and not in the future' do
    entry = build_entry(published_at: nil)

    assert_not entry.valid?
    assert_includes entry.errors[:published_at], "can't be blank"

    entry.published_at = 1.hour.from_now

    assert_not entry.valid?
    assert_includes entry.errors[:published_at], 'cannot be in the future'
  end

  test 'validates source and image urls use http or https' do
    entry = build_entry(source_url: 'ftp://example.com/story', image_url: 'not-a-url')

    assert_not entry.valid?
    assert_includes entry.errors[:source_url], 'must be a valid URL'
    assert_includes entry.errors[:image_url], 'must be a valid URL'
  end

  test 'final fields fall back when ai fields are blank' do
    entry = build_entry(
      title: 'Original title',
      description: 'Original description',
      ai_title: '',
      ai_description: '',
      keywords: ''
    )

    assert_equal 'Original title', entry.final_title
    assert_equal 'Original description', entry.final_description
    assert_equal Entry::DEFAULT_KEYWORDS, entry.final_keywords
  end

  test 'matching_text searches title and description case-insensitively' do
    title_match = create_entry(title: 'Metroid Prime returns', source_url: 'https://example.com/title-match')
    description_match = create_entry(
      title: 'Other story',
      description: 'A new METROID trailer arrived',
      source_url: 'https://example.com/description-match'
    )
    create_entry(title: 'Zelda update', source_url: 'https://example.com/no-match')

    assert_equal [title_match.id, description_match.id].sort, Entry.matching_text('metroid').pluck(:id).sort
  end

  test 'prompt delegates entry content to prompt builder' do
    entry = build_entry(content: 'Nintendo announced a new game.')

    assert_includes entry.prompt, 'Return the article in a JSON structure'
    assert_includes entry.prompt, 'Nintendo announced a new game.'
  end

  test 'display_tags prioritizes tags found in the title' do
    entry = create_entry(
      title: "Super Mario Galaxy Nintendo Switch: How Nintendo's 2007 Classic Holds Up in 2026",
      source_url: 'https://example.com/display-tags'
    )
    entry.tag_list = ['Bowser', 'Super Mario Galaxy', 'Mario']
    entry.save!

    assert_equal ['Super Mario Galaxy', 'Mario', 'Bowser'], entry.reload.display_tags.map(&:name)
  end

  private

  def build_entry(attributes = {})
    Entry.new(default_entry_attributes.merge(attributes))
  end

  def create_entry(attributes = {})
    Entry.create!(default_entry_attributes.merge(attributes))
  end

  def default_entry_attributes
    {
      site: @site,
      title: 'Nintendo story',
      description: 'Nintendo description',
      content: 'Nintendo content',
      source_url: "https://example.com/#{SecureRandom.uuid}",
      published_at: 1.hour.ago
    }
  end
end
