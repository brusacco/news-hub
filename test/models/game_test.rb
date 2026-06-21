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
      platforms: [{ 'platform' => { 'id' => 7, 'name' => 'Nintendo Switch' } }]
    )

    assert_equal 'Nintendo Switch', game.reload.platforms.first.dig('platform', 'name')
  end
end
