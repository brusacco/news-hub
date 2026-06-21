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
  end
end
