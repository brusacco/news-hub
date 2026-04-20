# frozen_string_literal: true

require 'test_helper'

class EntriesControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get entries_index_url
    assert_response :success
  end

  test 'show displays related entries even when recent unrelated entries exist' do
    site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    main_entry = create_entry(site:, title: 'Pragmata passes a million sales', source_url: 'https://example.com/main')
    main_entry.tag_list = ['Pragmata', 'Nintendo']
    main_entry.save!

    6.times do |index|
      unrelated = create_entry(
        site:,
        title: "Unrelated entry #{index}",
        source_url: "https://example.com/unrelated-#{index}",
        published_at: index.hours.ago
      )
      unrelated.tag_list = ['Zelda']
      unrelated.save!
    end

    related = create_entry(
      site:,
      title: 'Pragmata gets new update',
      source_url: 'https://example.com/pragmata-update',
      published_at: 10.minutes.ago
    )
    related.tag_list = ['Pragmata']
    related.save!

    get entry_url(main_entry)

    assert_response :success
    assert_includes response.body, 'Related Articles'
    assert_includes response.body, 'Pragmata gets new update'
  end

  private

  def create_entry(site:, title:, source_url:, published_at: 2.hours.ago)
    Entry.create!(
      site:,
      title:,
      description: "#{title} description",
      source_url:,
      source_name: 'Nintendo News Hub',
      published_at:
    )
  end
end
