# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportGameDetailsTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :parsed_response, :success?)
    SequenceHttpClient = Struct.new(:responses) do
      def get(url, query:)
        requests << { url:, query: }
        responses[requests.size - 1]
      end

      def requests
        @requests ||= []
      end
    end

    test 'requires an api key' do
      result = ImportGameDetails.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports detailed fields for a game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = SequenceHttpClient.new([FakeResponse.new(200, details_response, true)])
      io = StringIO.new

      result = ImportGameDetails.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:, io:)

      assert result.success?
      assert_equal 1, result.data
      assert_equal "https://api.rawg.io/api/games/#{game.rawg_id}", http_client.requests.first[:url]

      game.reload

      assert_equal 'Cyberpunk 2077: Ultimate Edition', game.name_original
      assert_equal '<p>Detailed description</p>', game.description
      assert_equal 'https://example.com', game.website
      assert_equal 'https://example.com/bg-extra.jpg', game.background_image_additional
      assert_equal 12, game.screenshots_count
      assert_equal 2, game.developers_count
      assert_equal 'CD PROJEKT RED', game.primary_developer_name
      assert_equal ['CD PROJEKT', 'CD PROJEKT RED'], game.developers.order(:rawg_id).pluck(:name)
      assert_equal 'cyberpunkgame', game.reddit_name
      assert_equal %w[CP2077 Cyberpunk], game.alternative_names
      assert_equal 'Mature', game.esrb_rating['name']
      assert_includes io.string, '[1/1] cyberpunk-2077: details imported'
    end

    private

    def details_response
      {
        'id' => 12_345,
        'slug' => 'cyberpunk-2077',
        'name' => 'Cyberpunk 2077',
        'name_original' => 'Cyberpunk 2077: Ultimate Edition',
        'description' => '<p>Detailed description</p>',
        'metacritic' => 89,
        'metacritic_platforms' => [{ 'metascore' => 90, 'platform' => { 'slug' => 'pc', 'name' => 'PC' } }],
        'released' => '2025-06-05',
        'tba' => false,
        'updated' => '2026-06-22T12:00:00Z',
        'background_image' => 'https://example.com/bg.jpg',
        'background_image_additional' => 'https://example.com/bg-extra.jpg',
        'website' => 'https://example.com',
        'rating' => 4.5,
        'rating_top' => 5,
        'ratings' => { '5' => 100 },
        'reactions' => { '1' => 20 },
        'added' => 200,
        'added_by_status' => { 'owned' => 80 },
        'playtime' => 45,
        'screenshots_count' => 12,
        'movies_count' => 3,
        'creators_count' => 4,
        'achievements_count' => 55,
        'parent_achievements_count' => '60',
        'reddit_url' => 'https://www.reddit.com/r/cyberpunkgame/',
        'reddit_name' => 'cyberpunkgame',
        'reddit_description' => 'Cyberpunk subreddit',
        'reddit_logo' => 'https://example.com/reddit-logo.png',
        'reddit_count' => 400,
        'twitch_count' => '12',
        'youtube_count' => '33',
        'reviews_text_count' => '7',
        'ratings_count' => 500,
        'suggestions_count' => 9,
        'alternative_names' => %w[CP2077 Cyberpunk],
        'metacritic_url' => 'https://www.metacritic.com/game/cyberpunk-2077',
        'parents_count' => 1,
        'additions_count' => 2,
        'game_series_count' => 1,
        'esrb_rating' => { 'id' => 4, 'name' => 'Mature' },
        'developers' => [
          {
            'id' => 9023,
            'name' => 'CD PROJEKT RED',
            'slug' => 'cd-projekt-red',
            'games_count' => 26,
            'image_background' => 'https://example.com/cdpr.jpg'
          },
          {
            'id' => 24,
            'name' => 'CD PROJEKT',
            'slug' => 'cd-projekt-sa',
            'games_count' => 7,
            'image_background' => 'https://example.com/cdp.jpg'
          }
        ],
        'platforms' => [{ 'platform' => { 'id' => 7, 'name' => 'Nintendo Switch' } }]
      }
    end
  end
end
