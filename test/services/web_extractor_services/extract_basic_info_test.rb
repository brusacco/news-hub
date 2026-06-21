# frozen_string_literal: true

require 'test_helper'

module WebExtractorServices
  class ExtractBasicInfoTest < ActiveSupport::TestCase
    test 'returns a blank title when no title metadata exists' do
      doc = Nokogiri::HTML('<html><head></head><body></body></html>')

      result = ExtractBasicInfo.call(doc)

      assert result.success?
      assert_equal '', result.data[:title]
    end
  end
end
