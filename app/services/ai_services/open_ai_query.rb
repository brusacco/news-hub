# frozen_string_literal: true

module AiServices
  class OpenAiQuery < ApplicationService
    def initialize(text)
      @text = text
    end

    def call
      client = OpenAI::Client.new(access_token: Rails.application.credentials.openai_access_token)

      response = client.chat(
        parameters: {
          model: 'gpt-4.1',
          messages: [{ role: 'user', content: @text }]
        }
      )

      result = response.dig('choices', 0, 'message', 'content')
      data = parse_response(result)
      handle_success(data)
    end

    private

    def parse_response(data)
      JSON.parse(data)
    end
  end
end
