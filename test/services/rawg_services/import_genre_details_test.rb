# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportGenreDetailsTest < ActiveSupport::TestCase
    test 'requires an api key' do
      result = ImportGenreDetails.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports detailed fields for a genre' do
      genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, genre_details_response, true)]
      )
      io = StringIO.new

      result = ImportGenreDetails.call(api_key: 'test-key', scope: Genre.where(id: genre.id), http_client:, io:)

      assert result.success?
      assert_equal 1, result.data
      assert_equal "https://api.rawg.io/api/genres/#{genre.rawg_id}", http_client.requests.first[:url]

      genre.reload

      assert_equal 'Action', genre.name
      assert_equal 'action', genre.slug
      assert_equal 191_775, genre.games_count
      assert_equal 'https://example.com/action.jpg', genre.image_background
      assert_includes genre.description, 'action game is a genre'
      assert_includes io.string, '[1/1] action: details imported'
    end

    test 'retries transient upstream failures and then imports genre details' do
      genre = Genre.create!(rawg_id: 4, name: 'Action', slug: 'action')
      responses = [
        RawgHttpClientHelpers::FakeResponse.new(502, {}, false),
        RawgHttpClientHelpers::FakeResponse.new(200, genre_details_response, true)
      ]
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(responses)
      io = StringIO.new
      delays = []

      result = ImportGenreDetails.call(
        api_key: 'test-key',
        scope: Genre.where(id: genre.id),
        http_client:,
        io:,
        sleeper: ->(seconds) { delays << seconds }
      )

      assert result.success?
      assert_equal 2, http_client.requests.size
      assert_equal [1], delays
      assert_includes(
        io.string,
        'Retry 1/3 for genre action in 1s after RAWG genre details request failed with status 502'
      )
    end

    private

    def genre_details_response
      {
        'id' => 4,
        'name' => 'Action',
        'slug' => 'action',
        'games_count' => 191_775,
        'image_background' => 'https://example.com/action.jpg',
        'description' => '<p>The action game is a genre with battles and fast reaction gameplay.</p>'
      }
    end
  end
end
