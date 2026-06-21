# frozen_string_literal: true

require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'entries for tag includes tags context once' do
    tag = Tag.create!(name: 'Cyberpunk 2077')
    tagged_entry = create_entry(title: 'Cyberpunk 2077 launches on Switch 2')
    tagged_entry.tag_list = [tag.name]
    tagged_entry.title_tag_list = [tag.name]
    tagged_entry.save!

    title_tag_only_entry = create_entry(title: 'Cyberpunk 2077 benchmark')
    title_tag_only_entry.title_tag_list = [tag.name]
    title_tag_only_entry.save!

    controller = TagsController.new
    entries = controller.send(:entries_for_tag, tag).to_a

    assert_equal [tagged_entry], entries
  end

  private

  def create_entry(title:)
    Entry.create!(
      site: @site,
      title:,
      description: "#{title} description",
      source_url: "https://example.com/#{SecureRandom.uuid}",
      published_at: 1.hour.ago
    )
  end
end
