# frozen_string_literal: true

require 'test_helper'

module RawgServices
  class ImportDeveloperDetailsTest < ActiveSupport::TestCase
    test 'requires an api key' do
      result = ImportDeveloperDetails.call(api_key: nil)

      assert_not result.success?
      assert_equal 'RAWG_API_KEY is required', result.error
    end

    test 'imports detailed fields for a developer' do
      developer = Developer.create!(rawg_id: 3678, name: 'Capcom', slug: 'capcom')
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(
        [RawgHttpClientHelpers::FakeResponse.new(200, developer_details_response, true)]
      )
      io = StringIO.new

      result = ImportDeveloperDetails.call(
        api_key: 'test-key',
        scope: Developer.where(id: developer.id),
        http_client:,
        io:
      )

      assert result.success?
      assert_equal 1, result.data
      assert_equal "https://api.rawg.io/api/developers/#{developer.rawg_id}", http_client.requests.first[:url]

      developer.reload

      assert_equal 'Capcom', developer.name
      assert_equal 'capcom', developer.slug
      assert_equal 480, developer.games_count
      assert_equal 'https://example.com/capcom.jpg', developer.image_background
      assert_includes developer.description, 'Capcom is a Japanese'
      assert_includes io.string, '[1/1] capcom: details imported'
    end

    test 'retries transient upstream failures and then imports developer details' do
      developer = Developer.create!(rawg_id: 3678, name: 'Capcom', slug: 'capcom')
      responses = [
        RawgHttpClientHelpers::FakeResponse.new(502, {}, false),
        RawgHttpClientHelpers::FakeResponse.new(200, developer_details_response, true)
      ]
      http_client = RawgHttpClientHelpers::SequenceHttpClient.new(responses)
      io = StringIO.new
      delays = []

      result = ImportDeveloperDetails.call(
        api_key: 'test-key',
        scope: Developer.where(id: developer.id),
        http_client:,
        io:,
        sleeper: ->(seconds) { delays << seconds }
      )

      assert result.success?
      assert_equal 2, http_client.requests.size
      assert_equal [1], delays
      assert_includes(
        io.string,
        'Retry 1/3 for developer capcom in 1s after RAWG developer details request failed with status 502'
      )
    end

    private

    def developer_details_response
      {
        'id' => 3678,
        'name' => 'Capcom',
        'slug' => 'capcom',
        'games_count' => 480,
        'image_background' => 'https://example.com/capcom.jpg',
        'description' => '<p>Capcom is a Japanese video game developer and publisher.</p>'
      }
    end
  end
end
