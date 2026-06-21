# frozen_string_literal: true

module TaggerTask
  DEFAULT_LIMIT = 100
  module_function

  def limit
    value = ENV.fetch('LIMIT', DEFAULT_LIMIT).to_i
    value.positive? ? value : DEFAULT_LIMIT
  end

  def tag_entries(entries)
    entries.each do |entry|
      tag_entry(entry)
    rescue StandardError => e
      puts e.message
      sleep 1
      retry
    end
  end

  def tag_entry(entry)
    result = WebExtractorServices::ExtractTags.call(entry.id)
    return unless result.success?

    tags = Array(result.data)
    tags += entry.entities.split(',') if entry.entities.present?
    tags = tags.flatten.map(&:strip).reject(&:blank?).uniq
    return if tags.blank?

    entry.tag_list = tags
    puts entry.source_url
    puts entry.tag_list
    puts '---------------------------------------------------'

    entry.save!
  end
end

desc 'Tagger'
task tagger: :environment do
  entries = Entry.order(id: :desc).limit(TaggerTask.limit)
  TaggerTask.tag_entries(entries)
end

namespace :tagger do
  desc 'Tag untagged entries. Set LIMIT=500 to control batch size.'
  task untagged: :environment do
    entries = Entry
              .tagger_scope
              .left_outer_joins(:taggings)
              .where(taggings: { id: nil })
              .limit(TaggerTask.limit)

    TaggerTask.tag_entries(entries)
  end
end
