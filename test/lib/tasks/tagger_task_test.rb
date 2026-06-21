# frozen_string_literal: true

require 'test_helper'
require 'rake'

class TaggerTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('tagger')
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'creates tags from entry entities when no existing tag matches' do
    entry = create_entry(entities: 'Zelda, Metroid Prime')

    TaggerTask.tag_entry(entry)

    assert_equal ['Metroid Prime', 'Zelda'], entry.reload.tag_list.sort
  end

  test 'can append one selected tag without replacing existing tags' do
    tag = Tag.create!(name: 'Zelda')
    entry = create_entry(title: 'Zelda update')
    entry.tag_list = ['Nintendo']
    entry.save!

    TaggerTask.tag_entry(entry, tag_id: tag.id, include_entities: false, replace: false)

    assert_equal %w[Nintendo Zelda], entry.reload.tag_list.sort
  end

  private

  def create_entry(attributes = {})
    Entry.create!(
      {
        site: @site,
        title: 'Nintendo story',
        description: 'Nintendo description',
        content: 'Nintendo content',
        source_url: "https://example.com/#{SecureRandom.uuid}",
        published_at: 1.hour.ago
      }.merge(attributes)
    )
  end
end
