# frozen_string_literal: true

require 'test_helper'

module AiServices
  class EntryPromptBuilderTest < ActiveSupport::TestCase
    test 'prompt enforces exact json shape and title entity preservation' do
      site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
      entry = Entry.create!(
        site: site,
        title: 'Super Mario Galaxy Nintendo Switch: How Nintendo Classic Holds Up',
        description: 'Source description',
        content: 'Nintendo discussed Super Mario Galaxy and its long-term legacy on Nintendo Switch.',
        source_url: 'https://example.com/super-mario-galaxy',
        source_name: 'Example Source',
        published_at: Time.current
      )

      prompt = EntryPromptBuilder.call(entry)

      assert_includes prompt, 'Preserve the main entity and search intent from the original title'
      assert_includes prompt, '"ai_summary": "Short summary"'
      assert_includes prompt, 'Original title: Super Mario Galaxy Nintendo Switch: How Nintendo Classic Holds Up'
      assert_includes prompt, 'use comma-separated values with no spaces after commas'
    end
  end
end
