# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class SyncGameDevelopersTest < ActiveSupport::TestCase
    test 'syncs cached developer fields and relations from raw data' do
      game = Game.create!(
        rawg_id: 12_345,
        name: 'Cyberpunk 2077',
        slug: 'cyberpunk-2077',
        raw_data: {
          'developers' => [
            {
              'id' => 9023,
              'name' => 'CD PROJEKT RED',
              'slug' => 'cd-projekt-red',
              'games_count' => 26,
              'image_background' => 'https://example.com/dev-bg.jpg'
            }
          ]
        }
      )

      result = SyncGameDevelopers.call(scope: Game.where(id: game.id))

      assert result.success?
      assert_equal 1, result.data

      game.reload

      assert_equal 1, game.developers_count
      assert_equal 'CD PROJEKT RED', game.primary_developer_name
      assert_equal ['CD PROJEKT RED'], game.developers.pluck(:name)
      assert_equal 'cd-projekt-red', game.rawg_developers.first['slug']
      assert_equal [game.id], Developer.find_by!(rawg_id: 9023).games.pluck(:id)
    end

    test 'clears stale relations when developers are missing' do
      developer = Developer.create!(rawg_id: 9023, name: 'CD PROJEKT RED', slug: 'cd-projekt-red')
      game = Game.create!(
        rawg_id: 12_345,
        name: 'Cyberpunk 2077',
        slug: 'cyberpunk-2077',
        raw_data: { 'developers' => [] },
        developers_count: 1,
        primary_developer_name: 'CD PROJEKT RED',
        rawg_developers: [{ 'id' => 9023, 'name' => 'CD PROJEKT RED', 'slug' => 'cd-projekt-red' }]
      )
      game.developers << developer

      result = SyncGameDevelopers.call(scope: Game.where(id: game.id))

      assert result.success?

      game.reload

      assert_equal 0, game.developers_count
      assert_nil game.primary_developer_name
      assert_empty game.developers
      assert_equal [], game.rawg_developers
    end
  end
end
