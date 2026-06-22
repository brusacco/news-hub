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
      rawg_genres: [{ 'id' => 4, 'name' => 'Action' }],
      rawg_developers: [{ 'id' => 9023, 'name' => 'CD PROJEKT RED', 'slug' => 'cd-projekt-red' }],
      alternative_names: ['CP2077'],
      esrb_rating: { 'id' => 4, 'name' => 'Mature' }
    )

    assert_equal 'Nintendo Switch', game.reload.platforms.first.dig('platform', 'name')
    assert_equal 'Action', game.rawg_genres.first['name']
    assert_equal 'CD PROJEKT RED', game.rawg_developers.first['name']
    assert_equal ['CP2077'], game.alternative_names
    assert_equal 'Mature', game.esrb_rating['name']
  end

  test 'has many genres' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')

    game.genres << genre

    assert_equal ['Action'], game.reload.genres.pluck(:name)
  end

  test 'has many developers' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    developer = Developer.create!(rawg_id: 9023, name: 'CD PROJEKT RED', slug: 'cd-projekt-red')

    game.developers << developer

    assert_equal ['CD PROJEKT RED'], game.reload.developers.pluck(:name)
  end

  test 'uses slug as route param' do
    game = Game.new(slug: 'cyberpunk-2077')

    assert_equal 'cyberpunk-2077', game.to_param
  end

  test 'builds default name tag from name' do
    assert_equal 'Cyberpunk 2077', Game.default_name_tag_for('Cyberpunk 2077 Nintendo Switch')
    assert_equal 'Metroid Prime 4', Game.default_name_tag_for('Metroid Prime 4 - Nintendo Switch')
  end

  test 'has many name tags' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')

    game.name_tag_list = ['Cyberpunk 2077']
    game.save!

    assert_equal ['Cyberpunk 2077'], game.reload.name_tag_list
  end

  test 'has many screenshots' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')

    game.screenshots.create!(rawg_id: 77, image: 'https://cdn.test/shot.jpg', position: 0)

    assert_equal [77], game.reload.screenshots.pluck(:rawg_id)
  end

  test 'orders popular games first' do
    lower = Game.create!(rawg_id: 1, name: 'Lower', slug: 'lower', ratings_count: 100, rating: 4.2, metacritic: 80)
    higher = Game.create!(rawg_id: 2, name: 'Higher', slug: 'higher', ratings_count: 500, rating: 4.0, metacritic: 70)

    assert_equal [higher, lower], Game.popular_first.where(id: [lower.id, higher.id]).to_a
  end
end
