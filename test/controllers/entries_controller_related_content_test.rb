# frozen_string_literal: true

require 'test_helper'

class EntriesControllerRelatedContentTest < ActionDispatch::IntegrationTest
  setup { @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com') }

  test 'related entries only match tags extracted from the title' do
    main_entry = create_entry(
      title: "Super Mario Galaxy Nintendo Switch: How Nintendo's 2007 Classic Holds Up in 2026",
      source_url: 'https://example.com/main-title-priority'
    )
    main_entry.tag_list = ['Bowser', 'Super Mario Galaxy', 'Mario']
    main_entry.title_tag_list = ['Super Mario Galaxy']
    main_entry.save!

    title_related = create_tagged_entry(
      title: 'Super Mario Galaxy receives new retrospective',
      source_url: 'https://example.com/title-related',
      tags: ['Super Mario Galaxy'],
      title_tags: ['Super Mario Galaxy'],
      published_at: 2.hours.ago
    )

    create_tagged_entry(
      title: 'Bowser gets a new profile',
      source_url: 'https://example.com/other-related',
      tags: ['Bowser'],
      published_at: 5.minutes.ago
    )

    assert_equal [title_related], build_controller(main_entry).send(:find_related_entries)
  end

  test 'related entries match title text while title tags are being backfilled' do
    main_entry = create_entry(
      title: 'Cyberpunk 2077 Redemption: CD Projekt Red Head Admits Work Remains',
      source_url: 'https://example.com/cyberpunk-main'
    )
    main_entry.tag_list = ['Cyberpunk 2077', 'Witcher']
    main_entry.save!

    title_match = create_tagged_entry(
      title: 'Nintendo Switch 2 Cyberpunk 2077 benchmark test',
      source_url: 'https://example.com/cyberpunk-title-match',
      tags: ['Cyberpunk 2077'],
      published_at: 2.hours.ago
    )

    create_tagged_entry(
      title: 'CD Projekt Red talks about future plans',
      source_url: 'https://example.com/cyberpunk-tag-only',
      tags: ['Cyberpunk 2077'],
      published_at: 5.minutes.ago
    )

    assert_equal [title_match], build_controller(main_entry).send(:find_related_entries)
  end

  test 'related entries include title matches older than a week' do
    main_entry = create_entry(
      title: 'Cyberpunk 2077 Redemption: CD Projekt Red Head Admits Work Remains',
      source_url: 'https://example.com/cyberpunk-recent'
    )
    main_entry.tag_list = ['Cyberpunk 2077']
    main_entry.save!

    older_match = create_tagged_entry(
      title: 'Cyberpunk 2077 benchmark results on Nintendo Switch 2',
      source_url: 'https://example.com/cyberpunk-older',
      tags: ['Cyberpunk 2077'],
      published_at: 2.months.ago
    )

    assert_equal [older_match], build_controller(main_entry).send(:find_related_entries)
  end

  test 'related games are ordered by confidence first' do
    entry = create_entry(title: 'Metroid Prime 4 preview', source_url: 'https://example.com/metroid-prime-4')
    game_one = Game.create!(rawg_id: 1, name: 'Metroid Prime 4', slug: 'metroid-prime-4')
    game_two = Game.create!(rawg_id: 2, name: 'Metroid Prime Remastered', slug: 'metroid-prime-remastered')
    EntryGame.create!(entry:, game: game_two, confidence: 50, match_source: 'tag', matched_text: 'Metroid Prime')
    EntryGame.create!(entry:, game: game_one, confidence: 90, match_source: 'title', matched_text: 'Metroid Prime 4')

    assert_equal [game_one, game_two], build_controller(entry).send(:related_games)
  end

  private

  def build_controller(entry)
    EntriesController.new.tap do |controller|
      controller.instance_variable_set(:@entry, entry)
      controller.instance_variable_set(:@games, [])
    end
  end

  def create_entry(title:, source_url:, published_at: 2.hours.ago)
    Entry.create!(
      site: @site,
      title:,
      description: "#{title} description",
      source_url:,
      source_name: 'Nintendo News Hub',
      published_at:
    )
  end

  def create_tagged_entry(title:, source_url:, tags:, title_tags: [], published_at: 2.hours.ago)
    entry = create_entry(title:, source_url:, published_at:)
    entry.tag_list = tags
    entry.title_tag_list = title_tags if title_tags.any?
    entry.save!
    entry
  end
end
