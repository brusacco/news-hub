# frozen_string_literal: true

require 'test_helper'
require 'json'

module RawgServices
  class ImportGameDetailsTest < ActiveSupport::TestCase
    test 'requires an api key' do
      result = ImportGameDetails.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports detailed fields for a game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, details_response, true)]
      )
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

    test 'retries transient upstream failures and then imports details' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      responses = [
        RawgHttpClientHelpers::FakeResponse.new(502, {}, false),
        RawgHttpClientHelpers::FakeResponse.new(200, details_response, true)
      ]
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(responses)
      io = StringIO.new
      delays = []

      result = ImportGameDetails.call(
        api_key: 'test-key',
        scope: Game.where(id: game.id),
        http_client:,
        io:,
        sleeper: ->(seconds) { delays << seconds }
      )

      assert result.success?
      assert_equal 2, http_client.requests.size
      assert_equal [1], delays
      assert_includes(
        io.string,
        'Retry 1/3 for cyberpunk-2077 in 1s after RAWG game details request failed with status 502'
      )
      assert_equal 'CD PROJEKT RED', game.reload.primary_developer_name
    end

    test 'does not retry non-retryable failures' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(404, {}, false)]
      )
      io = StringIO.new
      delays = []

      result = ImportGameDetails.call(
        api_key: 'test-key',
        scope: Game.where(id: game.id),
        http_client:,
        io:,
        sleeper: ->(seconds) { delays << seconds }
      )

      assert_not result.success?
      assert_equal 'RAWG game details request failed with status 404 for game 12345', result.error
      assert_equal 1, http_client.requests.size
      assert_empty delays
    end

    private

    def details_response
      @details_response ||= JSON.parse(file_fixture('rawg_game_details_response.json').read)
    end
  end
end
