# frozen_string_literal: true

require 'test_helper'
require 'rake'

class TagsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('tags:cleanup_forbidden')
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
    Rake::Task['tags:cleanup_forbidden'].reenable
  end

  test 'cleanup forbidden tags is dry run by default' do
    Tag.create!(name: 'Nintendo')

    Rake::Task['tags:cleanup_forbidden'].invoke

    assert Tag.exists?(name: 'Nintendo')
  end

  test 'cleanup forbidden tags deletes blocked tags and keeps allowed tags' do
    previous_dry_run = ENV.fetch('DRY_RUN', nil)
    ENV['DRY_RUN'] = 'false'
    forbidden_tag = Tag.create!(name: 'Nintendo')
    allowed_tag = Tag.create!(name: 'Cyberpunk 2077')
    entry = create_entry
    entry.tag_list = [forbidden_tag.name, allowed_tag.name]
    entry.save!

    Rake::Task['tags:cleanup_forbidden'].invoke

    assert_not Tag.exists?(forbidden_tag.id)
    assert Tag.exists?(allowed_tag.id)
    assert_not_includes entry.reload.tag_list, forbidden_tag.name
    assert_includes entry.tag_list, allowed_tag.name
  ensure
    ENV['DRY_RUN'] = previous_dry_run
  end

  private

  def create_entry
    Entry.create!(
      site: @site,
      title: 'Cyberpunk 2077 update',
      source_url: "https://example.com/#{SecureRandom.uuid}",
      published_at: 1.hour.ago
    )
  end
end
