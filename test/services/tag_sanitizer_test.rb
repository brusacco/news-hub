# frozen_string_literal: true

require 'test_helper'

class TagSanitizerTest < ActiveSupport::TestCase
  test 'filters generic platform region and short tags' do
    tags = ['Nintendo Switch 2', 'Nintendo', 'Switch', 'PC', 'US', 'S', 'Europe', 'Devil May Cry 5']

    assert_equal ['Devil May Cry 5'], TagSanitizer.call(tags)
  end

  test 'canonicalizes case and deduplicates case-insensitively' do
    tags = ['CAPCOM', 'Capcom', 'devil may cry 5', 'PC-9801']

    assert_equal ['Capcom', 'Devil May Cry 5', 'PC-9801'], TagSanitizer.call(tags)
  end

  test 'keeps specific multi-word titles while blocking generic single words' do
    tags = ['Star Fox', 'Fox', 'Citizen Sleeper 2', 'Run', 'Kiyo: Bunny Tyranny']

    assert_equal ['Star Fox', 'Citizen Sleeper 2', 'Kiyo: Bunny Tyranny'], TagSanitizer.call(tags)
  end
end
