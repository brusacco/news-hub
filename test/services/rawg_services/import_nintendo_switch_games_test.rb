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

    SequenceHttpClient = Struct.new(:responses) do
      def get(_url, query:)
        queries << query
        responses[queries.size - 1]
      end

      def queries
        @queries ||= []
      end
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
      assert_equal 'Action', game.rawg_genres.first['name']
      assert_equal ['Action'], game.genres.pluck(:name)
    end

    test 'continues importing pages until rawg has no next page' do
      http_client = SequenceHttpClient.new(
        [
          FakeResponse.new(200, paginated_response(12_345, 'https://api.rawg.io/api/games?page=2'), true),
          FakeResponse.new(200, paginated_response(67_890, nil), true)
        ]
      )

      result = ImportNintendoSwitchGames.call(api_key: 'test-key', page_size: 1, http_client:)

      assert result.success?
      assert_equal 2, result.data
      assert_equal [1, 2], http_client.queries.pluck(:page)
      assert_equal 2, Game.where(rawg_id: [12_345, 67_890]).count
    end

    test 'stops at pages limit when provided' do
      http_client = SequenceHttpClient.new(
        [
          FakeResponse.new(200, paginated_response(12_345, 'https://api.rawg.io/api/games?page=2'), true),
          FakeResponse.new(200, paginated_response(67_890, nil), true)
        ]
      )

      result = ImportNintendoSwitchGames.call(api_key: 'test-key', pages: 1, page_size: 1, http_client:)

      assert result.success?
      assert_equal 1, result.data
      assert_equal [1], http_client.queries.pluck(:page)
      assert_equal 1, Game.where(rawg_id: [12_345, 67_890]).count
    end

    private

    def paginated_response(rawg_id, next_url)
      rawg_response.merge(
        'next' => next_url,
        'results' => [
          rawg_response['results'].first.merge(
            'id' => rawg_id,
            'slug' => "game-#{rawg_id}",
            'name' => "Game #{rawg_id}"
          )
        ]
      )
    end

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
            'platforms' => [
              {
                'platform' => {
                  'id' => 7,
                  'name' => 'Nintendo Switch'
                }
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
