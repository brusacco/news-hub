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
    main_entry.tag_list = %w[Pragmata Nintendo]
    main_entry.title_tag_list = ['Pragmata']
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
    related.title_tag_list = ['Pragmata']
    related.save!

    get entry_url(main_entry)

    assert_response :success
    assert_includes response.body, 'Related Articles'
    assert_includes response.body, 'Pragmata gets new update'
  end

  test 'related entries only match tags extracted from the title' do
    site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    main_entry = create_entry(
      site:,
      title: "Super Mario Galaxy Nintendo Switch: How Nintendo's 2007 Classic Holds Up in 2026",
      source_url: 'https://example.com/main-title-priority'
    )
    main_entry.tag_list = ['Bowser', 'Super Mario Galaxy', 'Mario']
    main_entry.title_tag_list = ['Super Mario Galaxy']
    main_entry.save!

    title_related = create_entry(
      site:,
      title: 'Super Mario Galaxy receives new retrospective',
      source_url: 'https://example.com/title-related',
      published_at: 2.hours.ago
    )
    title_related.tag_list = ['Super Mario Galaxy']
    title_related.title_tag_list = ['Super Mario Galaxy']
    title_related.save!

    other_related = create_entry(
      site:,
      title: 'Bowser gets a new profile',
      source_url: 'https://example.com/other-related',
      published_at: 5.minutes.ago
    )
    other_related.tag_list = ['Bowser']
    other_related.save!

    controller = EntriesController.new
    controller.instance_variable_set(:@entry, main_entry)

    related_entries = controller.send(:find_related_entries)

    assert_equal [title_related], related_entries
  end

  test 'related entries match title text while title tags are being backfilled' do
    site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    main_entry = create_entry(
      site:,
      title: 'Cyberpunk 2077 Redemption: CD Projekt Red Head Admits Work Remains',
      source_url: 'https://example.com/cyberpunk-main'
    )
    main_entry.tag_list = ['Cyberpunk 2077', 'Witcher']
    main_entry.save!

    title_match = create_entry(
      site:,
      title: 'Nintendo Switch 2 Cyberpunk 2077 benchmark test',
      source_url: 'https://example.com/cyberpunk-title-match',
      published_at: 2.hours.ago
    )
    title_match.tag_list = ['Cyberpunk 2077']
    title_match.save!

    tag_only_match = create_entry(
      site:,
      title: 'CD Projekt Red talks about future plans',
      source_url: 'https://example.com/cyberpunk-tag-only',
      published_at: 5.minutes.ago
    )
    tag_only_match.tag_list = ['Cyberpunk 2077']
    tag_only_match.save!

    controller = EntriesController.new
    controller.instance_variable_set(:@entry, main_entry)

    related_entries = controller.send(:find_related_entries)

    assert_equal [title_match], related_entries
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
