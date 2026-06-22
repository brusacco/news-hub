# frozen_string_literal: true

require 'test_helper'

class GenresControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'www.nintendonewshub.com'
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'routes genres index' do
    assert_routing '/genres', controller: 'genres', action: 'index'
  end

  test 'routes genres show' do
    assert_routing '/genres/action', controller: 'genres', action: 'show', id: 'action'
  end

  test 'genre show includes related news for linked games' do
    genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')
    game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    game.genres << genre

    entry = Entry.create!(
      site: @site,
      title: 'Cyberpunk 2077 arrives on Nintendo platforms',
      description: 'Cyberpunk 2077 description',
      source_url: 'https://example.com/cyberpunk-news',
      published_at: 1.hour.ago
    )
    EntryGame.create!(entry:, game:, match_source: 'title_tag', confidence: 100)

    controller = GenresController.new
    related_entries = controller.send(:related_entries, genre)

    assert_equal [entry], related_entries.to_a
  end
end
