# frozen_string_literal: true

module RawgHttpClientHelpers
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
end
