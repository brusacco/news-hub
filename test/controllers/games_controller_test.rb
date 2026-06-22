# frozen_string_literal: true

require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  test 'routes games index' do
    assert_routing '/games', controller: 'games', action: 'index'
  end

  test 'routes games show' do
    assert_routing '/games/cyberpunk-2077', controller: 'games', action: 'show', id: 'cyberpunk-2077'
  end

  test 'related games require all genres to match' do
    action = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')
    rpg = Genre.create!(rawg_id: 5, name: 'RPG', slug: 'rpg')
    strategy = Genre.create!(rawg_id: 6, name: 'Strategy', slug: 'strategy')

    source_game = Game.create!(rawg_id: 100, name: 'Source Game', slug: 'source-game')
    full_match = Game.create!(rawg_id: 101, name: 'Full Match', slug: 'full-match')
    partial_match = Game.create!(rawg_id: 102, name: 'Partial Match', slug: 'partial-match')
    superset_match = Game.create!(rawg_id: 103, name: 'Superset Match', slug: 'superset-match')

    source_game.genres << [action, rpg]
    full_match.genres << [action, rpg]
    partial_match.genres << [action]
    superset_match.genres << [action, rpg, strategy]

    controller = GamesController.new
    related_games = controller.send(:related_games, source_game).to_a

    assert_includes related_games, full_match
    assert_includes related_games, superset_match
    assert_not_includes related_games, partial_match
  end
end
