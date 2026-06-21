# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class SyncGameGenresTest < ActiveSupport::TestCase
    test 'creates genre relations from stored rawg genre payload' do
      game = Game.create!(
        rawg_id: 1,
        name: 'Cyberpunk 2077',
        slug: 'cyberpunk-2077',
        rawg_genres: [{ 'id' => 4, 'name' => 'Action', 'slug' => 'action' }]
      )

      result = SyncGameGenres.call

      assert result.success?
      assert_equal 1, result.data
      assert_equal ['Action'], game.reload.genres.pluck(:name)
    end

    test 'does not clear enriched genre image when game payload has no image' do
      genre = Genre.create!(
        rawg_id: 4,
        name: 'Action',
        slug: 'action',
        image_background: 'https://media.rawg.io/media/genre/action.jpg',
        games_count: 180_000,
        raw_data: { 'id' => 4, 'name' => 'Action', 'image_background' => 'https://media.rawg.io/media/genre/action.jpg' }
      )
      game = Game.create!(
        rawg_id: 1,
        name: 'Cyberpunk 2077',
        slug: 'cyberpunk-2077',
        rawg_genres: [{ 'id' => 4, 'name' => 'Action', 'slug' => 'action' }]
      )

      SyncGameGenres.call

      genre.reload

      assert_equal ['Action'], game.reload.genres.pluck(:name)
      assert_equal 'https://media.rawg.io/media/genre/action.jpg', genre.image_background
      assert_equal 180_000, genre.games_count
      assert_equal 'https://media.rawg.io/media/genre/action.jpg', genre.raw_data['image_background']
    end
  end
end
