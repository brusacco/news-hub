# frozen_string_literal: true

require 'test_helper'

class GameMatcherTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'matches exact game names in entry titles with high confidence' do
    game = create_game(name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    entry = create_entry(title: 'Cyberpunk 2077 launches on Nintendo Switch')

    matches = GameMatcher.link_entry!(entry, games: Game.where(id: game.id))

    assert_equal [game.id], matches.map(&:game_id)
    assert_equal 'title', entry.entry_games.first.match_source
    assert_equal 100, entry.entry_games.first.confidence
  end

  test 'does not match partial game names' do
    game = create_game(name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    entry = create_entry(title: 'Cyberpunk sequel rumors continue')

    matches = GameMatcher.link_entry!(entry, games: Game.where(id: game.id))

    assert_empty matches
    assert_empty entry.entry_games
  end

  test 'does not match short game names from body content' do
    game = create_game(name: 'Ys', slug: 'ys')
    entry = create_entry(content: 'Nintendo says this update is available now.')

    matches = GameMatcher.link_entry!(entry, games: Game.where(id: game.id))

    assert_empty matches
    assert_empty entry.entry_games
  end

  test 'allows short game names from title tags' do
    game = create_game(name: 'Ys', slug: 'ys')
    entry = create_entry(title: 'RPG update')
    entry.title_tag_list = ['Ys']
    entry.save!

    matches = GameMatcher.link_entry!(entry, games: Game.where(id: game.id))

    assert_equal [game.id], matches.map(&:game_id)
    assert_equal 'title_tags', entry.entry_games.first.match_source
  end

  test 'replaces stale links by default' do
    stale_game = create_game(name: 'Zelda', slug: 'zelda')
    current_game = create_game(name: 'Metroid Prime 4', slug: 'metroid-prime-4')
    entry = create_entry(title: 'Metroid Prime 4 preview')
    EntryGame.create!(entry:, game: stale_game, match_source: 'title', confidence: 100, matched_text: stale_game.name)

    GameMatcher.link_entry!(entry)

    assert_equal [current_game.id], entry.reload.games.pluck(:id)
  end

  test 'can preserve existing links when replace is false' do
    existing_game = create_game(name: 'Zelda', slug: 'zelda')
    current_game = create_game(name: 'Metroid Prime 4', slug: 'metroid-prime-4')
    entry = create_entry(title: 'Metroid Prime 4 preview')
    EntryGame.create!(
      entry:,
      game: existing_game,
      match_source: 'title',
      confidence: 100,
      matched_text: existing_game.name
    )

    GameMatcher.link_entry!(entry, games: Game.where(id: current_game.id), replace: false)

    assert_equal [existing_game.id, current_game.id].sort, entry.reload.games.pluck(:id).sort
  end

  private

  def create_game(name:, slug:)
    Game.create!(rawg_id: SecureRandom.random_number(100_000), name:, slug:)
  end

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
