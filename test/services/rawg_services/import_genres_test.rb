# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportGenresTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :parsed_response, :success?)
    FakeHttpClient = Struct.new(:response) do
      def get(_url, query:)
        @query = query
        response
      end

      attr_reader :query
    end

    test 'requires an api key' do
      result = ImportGenres.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports genres from rawg response' do
      http_client = FakeHttpClient.new(FakeResponse.new(200, rawg_response, true))

      result = ImportGenres.call(api_key: 'test-key', pages: 1, page_size: 1, http_client:)

      assert result.success?
      assert_equal 1, result.data
      assert_equal 1, http_client.query[:page]

      genre = Genre.find_by!(rawg_id: 4)

      assert_equal 'Action', genre.name
      assert_equal 'action', genre.slug
      assert_equal 180_000, genre.games_count
      assert_equal 'https://media.rawg.io/media/genre/action.jpg', genre.image_background
    end

    private

    def rawg_response
      {
        'next' => nil,
        'results' => [
          {
            'id' => 4,
            'name' => 'Action',
            'slug' => 'action',
            'games_count' => 180_000,
            'image_background' => 'https://media.rawg.io/media/genre/action.jpg'
          }
        ]
      }
    end
  end
end
