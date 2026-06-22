# frozen_string_literal: true

require 'test_helper'
require 'json'

module RawgServices
  class ImportGameScreenshotsTest < ActiveSupport::TestCase
    test 'requires an api key' do
      result = ImportGameScreenshots.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports screenshots for a game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, screenshot_response, true)]
      )

      result = ImportGameScreenshots.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:)

      assert result.success?
      assert_equal 2, result.data
      assert_equal "https://api.rawg.io/api/games/#{game.rawg_id}/screenshots", http_client.requests.first[:url]

      screenshots = game.reload.screenshots
      assert_equal 2, screenshots.count
      assert_equal [111, 222], screenshots.pluck(:rawg_id)
      assert_equal [0, 1], screenshots.pluck(:position)
    end

    test 'replaces stale screenshots by default' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      game.screenshots.create!(rawg_id: 999, image: 'https://cdn.test/stale.jpg', position: 0)
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, screenshot_response, true)]
      )

      result = ImportGameScreenshots.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:)

      assert result.success?
      assert_equal [111, 222], game.reload.screenshots.pluck(:rawg_id)
    end

    test 'prints progress for each processed game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, screenshot_response, true)]
      )
      io = StringIO.new

      result = ImportGameScreenshots.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:, io:)

      assert result.success?
      assert_includes io.string, '[1/1] cyberpunk-2077: 2 screenshots'
    end

    test 'retries transient upstream failures and then imports screenshots' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      responses = [
        RawgHttpClientHelpers::FakeResponse.new(502, {}, false),
        RawgHttpClientHelpers::FakeResponse.new(200, screenshot_response, true)
      ]
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(responses)
      io = StringIO.new
      delays = []

      result = ImportGameScreenshots.call(
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
        'Retry 1/3 for cyberpunk-2077 screenshots in 1s after RAWG screenshots request failed with status 502'
      )
      assert_equal [111, 222], game.reload.screenshots.pluck(:rawg_id)
    end

    test 'does not retry non-retryable screenshot failures' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(404, {}, false)]
      )
      delays = []

      result = ImportGameScreenshots.call(
        api_key: 'test-key',
        scope: Game.where(id: game.id),
        http_client:,
        sleeper: ->(seconds) { delays << seconds }
      )

      assert_not result.success?
      assert_equal 'RAWG screenshots request failed with status 404 for game 12345', result.error
      assert_equal 1, http_client.requests.size
      assert_empty delays
    end

    private

    def screenshot_response
      @screenshot_response ||= JSON.parse(file_fixture('rawg_game_screenshots_response.json').read)
    end
  end
end
