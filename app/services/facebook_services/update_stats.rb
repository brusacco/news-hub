# frozen_string_literal: true

module FacebookServices
  class UpdateStats < ApplicationService
    def initialize(id)
      @entry_id = id
    end

    def call
      entry = Entry.find(@entry_id)
      response = fetch_facebook_data(entry.url)
      data = parse_response(response)
      engagement = calculate_engagement(data['engagement'])
      handle_success(engagement)
    end

    private

    def fetch_facebook_data(url)
      token = '1442100149368278|52cd0715eae80b831d25db730046bc93'
      request = "https://graph.facebook.com/v14.0/?id=#{CGI.escape(url)}&fields=engagement&access_token=#{token}"
      HTTParty.get(request)
    end

    def parse_response(response)
      JSON.parse(response.body)
    end

    def calculate_engagement(engagement)
      total = engagement['reaction_count'] + engagement['comment_count'] + engagement['share_count'] + engagement['comment_plugin_count']
      engagement['total_count'] = total
      engagement
    end
  end
end
