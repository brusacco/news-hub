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

  test 'filters generic short and duplicate entity tags' do
    entry = create_entry(
      entities: 'Nintendo Switch 2, Switch, PC, US, eShop, esHop, CAPCOM, Capcom, Devil May Cry 5, S, OFF'
    )

    TaggerTask.tag_entry(entry)

    assert_equal ['Capcom', 'Devil May Cry 5'], entry.reload.tag_list.sort
  end

  test 'prioritizes tags extracted from the title before entity tags' do
    Tag.create!(name: 'Super Mario Galaxy')
    Tag.create!(name: 'Mario')
    entry = create_entry(
      title: "Super Mario Galaxy Nintendo Switch: How Nintendo's 2007 Classic Holds Up in 2026",
      entities: 'Bowser, Super Mario Galaxy'
    )

    TaggerTask.tag_entry(entry)

    assert_equal 'Super Mario Galaxy', entry.reload.tag_list.first
    assert_equal ['Super Mario Galaxy', 'Mario'], entry.title_tag_list
    assert_includes entry.tag_list, 'Bowser'
  end

  test 'can append one selected tag without replacing existing tags' do
    tag = Tag.create!(name: 'Zelda')
    entry = create_entry(title: 'Zelda update')
    entry.tag_list = ['Nintendo']
    entry.save!

    TaggerTask.tag_entry(entry, tag_id: tag.id, include_entities: false, replace: false)

    assert_equal %w[Nintendo Zelda], entry.reload.tag_list.sort
  end

  test 'does not save an entry when computed tags are unchanged' do
    Tag.create!(name: 'Zelda')
    entry = create_entry(title: 'Zelda update')

    TaggerTask.tag_entry(entry)

    assert_no_changes -> { entry.reload.updated_at } do
      TaggerTask.tag_entry(entry)
    end
  end

  test 'limit supports all for uncapped backfills' do
    previous_limit = ENV.fetch('LIMIT', nil)
    ENV['LIMIT'] = 'all'

    assert_nil TaggerTask.limit
  ensure
    ENV['LIMIT'] = previous_limit
  end

  test 'entries missing title tags excludes entries that already have title tags' do
    missing_title_tags = create_entry(title: 'Cyberpunk 2077 update')
    tagged = create_entry(title: 'Zelda update')
    tagged.title_tag_list = ['Zelda']
    tagged.save!

    entry_ids = TaggerTask.entries_missing_title_tags.pluck(:id)

    assert_includes entry_ids, missing_title_tags.id
    assert_not_includes entry_ids, tagged.id
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
