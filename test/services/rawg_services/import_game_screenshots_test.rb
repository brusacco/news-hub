# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportGameScreenshotsTest < ActiveSupport::TestCase
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
      result = ImportGameScreenshots.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports screenshots for a game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = SequenceHttpClient.new([FakeResponse.new(200, screenshot_response, true)])

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
      http_client = SequenceHttpClient.new([FakeResponse.new(200, screenshot_response, true)])

      result = ImportGameScreenshots.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:)

      assert result.success?
      assert_equal [111, 222], game.reload.screenshots.pluck(:rawg_id)
    end

    test 'prints progress for each processed game' do
      game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
      http_client = SequenceHttpClient.new([FakeResponse.new(200, screenshot_response, true)])
      io = StringIO.new

      result = ImportGameScreenshots.call(api_key: 'test-key', scope: Game.where(id: game.id), http_client:, io:)

      assert result.success?
      assert_includes io.string, '[1/1] cyberpunk-2077: 2 screenshots'
    end

    private

    def screenshot_response
      {
        'results' => [
          {
            'id' => 111,
            'image' => 'https://cdn.test/1.jpg',
            'width' => 1280,
            'height' => 720,
            'is_deleted' => false
          },
          {
            'id' => 222,
            'image' => 'https://cdn.test/2.jpg',
            'width' => 1920,
            'height' => 1080,
            'is_deleted' => false
          }
        ]
      }
    end
  end
end
