# frozen_string_literal: true

require 'test_helper'

class GenreTest < ActiveSupport::TestCase
  test 'requires rawg id name and slug' do
    genre = Genre.new

    assert_not genre.valid?
    assert_includes genre.errors[:rawg_id], "can't be blank"
    assert_includes genre.errors[:name], "can't be blank"
    assert_includes genre.errors[:slug], "can't be blank"
  end

  test 'has many games' do
    genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')

    genre.games << game

    assert_equal ['Cyberpunk 2077'], genre.reload.games.pluck(:name)
  end
end
