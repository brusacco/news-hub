# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test 'requires rawg id name and slug' do
    game = Game.new

    assert_not game.valid?
    assert_includes game.errors[:rawg_id], "can't be blank"
    assert_includes game.errors[:name], "can't be blank"
    assert_includes game.errors[:slug], "can't be blank"
  end

  test 'serializes raw payload fields' do
    game = Game.create!(
      rawg_id: 1,
      name: 'Cyberpunk 2077',
      slug: 'cyberpunk-2077',
      platforms: [{ 'platform' => { 'id' => 7, 'name' => 'Nintendo Switch' } }],
      rawg_genres: [{ 'id' => 4, 'name' => 'Action' }]
    )

    assert_equal 'Nintendo Switch', game.reload.platforms.first.dig('platform', 'name')
    assert_equal 'Action', game.rawg_genres.first['name']
  end

  test 'has many genres' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')

    game.genres << genre

    assert_equal ['Action'], game.reload.genres.pluck(:name)
  end
end
