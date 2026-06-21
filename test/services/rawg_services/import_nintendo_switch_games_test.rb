# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportNintendoSwitchGamesTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :parsed_response, :success?)
    FakeHttpClient = Struct.new(:response) do
      def get(_url, query:)
        @query = query
        response
      end

      attr_reader :query
    end

    test 'requires an api key' do
      result = ImportNintendoSwitchGames.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports nintendo switch games from rawg response' do
      http_client = FakeHttpClient.new(FakeResponse.new(200, rawg_response, true))

      result = ImportNintendoSwitchGames.call(api_key: 'test-key', pages: 1, page_size: 1, http_client:)

      assert result.success?
      assert_equal 1, result.data
      assert_equal 7, http_client.query[:platforms]

      game = Game.find_by!(rawg_id: 12_345)

      assert_equal 'Cyberpunk 2077', game.name
      assert_equal 'cyberpunk-2077', game.slug
      assert_equal Date.new(2025, 6, 5), game.released
      assert_equal 7, game.platforms.first.dig('platform', 'id')
    end

    private

    def rawg_response
      {
        'next' => nil,
        'results' => [
          {
            'id' => 12_345,
            'slug' => 'cyberpunk-2077',
            'name' => 'Cyberpunk 2077',
            'released' => '2025-06-05',
            'tba' => false,
            'background_image' => 'https://media.rawg.io/media/games/cyberpunk.jpg',
            'rating' => 4.5,
            'rating_top' => 5,
            'ratings_count' => 100,
            'metacritic' => 86,
            'playtime' => 40,
            'updated' => '2026-06-01T10:00:00Z',
            'platforms' => [
              {
                'platform' => {
                  'id' => 7,
                  'name' => 'Nintendo Switch',
                  'slug' => 'nintendo-switch'
                },
                'released_at' => '2025-06-05'
              }
            ],
            'genres' => [{ 'id' => 4, 'name' => 'Action', 'slug' => 'action' }],
            'stores' => []
          }
        ]
      }
    end
  end
end
