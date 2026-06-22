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
          model: ENV.fetch('OPENAI_MODEL', 'gpt-5-mini'),
          messages: [{ role: 'user', content: @text }]
        }
      )

      result = response.dig('choices', 0, 'message', 'content')
      data = parse_response(result)
      handle_success(data)
    end

    private

    def parse_response(data)
      JSON.parse(clean_json_response(data))
    end

    def clean_json_response(data)
      data.to_s.strip.gsub(/\A```(?:json)?\s*|\s*```\z/, '')
    end
  end
end
