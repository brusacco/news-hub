# frozen_string_literal: true

require 'test_helper'

class EntriesControllerMetaTagsTest < ActionDispatch::IntegrationTest
  setup { @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com') }

  test 'entry seo title prefers branded title when it fits' do
    entry = create_entry(title: 'Mario Kart World hands-on', source_url: 'https://example.com/mkw')

    assert_equal(
      'Mario Kart World hands-on | Nintendo News Hub',
      build_controller(entry).send(:entry_seo_title)
    )
  end

  test 'entry seo description includes related game names for stronger ctr copy' do
    entry = create_entry(title: 'Metroid Prime 4 preview', source_url: 'https://example.com/mp4')
    game = Game.create!(rawg_id: 3, name: 'Metroid Prime 4', slug: 'metroid-prime-4')
    EntryGame.create!(entry:, game:, confidence: 80, match_source: 'title', matched_text: 'Metroid Prime 4')
    controller = build_controller(entry)
    controller.instance_variable_set(:@games, controller.send(:related_games))

    description = controller.send(:entry_seo_description)

    assert_includes description, 'Metroid Prime 4'
    assert_includes description, 'Nintendo News Hub'
  end

  private

  def build_controller(entry)
    EntriesController.new.tap do |controller|
      controller.instance_variable_set(:@entry, entry)
      controller.instance_variable_set(:@games, [])
    end
  end

  def create_entry(title:, source_url:)
    Entry.create!(
      site: @site,
      title:,
      description: "#{title} description",
      source_url:,
      source_name: 'Nintendo News Hub',
      published_at: 2.hours.ago
    )
  end
end
