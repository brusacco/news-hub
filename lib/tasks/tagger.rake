# frozen_string_literal: true

module TaggerTask
  DEFAULT_LIMIT = 100

  module_function

  def limit
    value = ENV.fetch('LIMIT', DEFAULT_LIMIT).to_i
    value.positive? ? value : DEFAULT_LIMIT
  end

  def tag_entries(entries, tag_id: nil, include_entities: true, replace: true)
    entries.each do |entry|
      tag_entry(entry, tag_id:, include_entities:, replace:)
    rescue StandardError => e
      puts e.message
      sleep 1
      retry
    end
  end

  def tag_entry(entry, tag_id: nil, include_entities: true, replace: true)
    title_tag_names = normalize_tags(extracted_title_tags(entry, tag_id:))
    tags = normalize_tags(candidate_tags(entry, title_tag_names, tag_id:, include_entities:))
    return if tags.blank?

    apply_tags(entry, tags, replace:)
    apply_title_tags(entry, title_tag_names, replace:)
    log_tagged_entry(entry)

    entry.save!
  end

  def log_tagged_entry(entry)
    puts entry.source_url
    puts entry.tag_list
    puts "Title tags: #{entry.title_tag_list.join(', ')}" if entry.title_tag_list.any?
    puts '---------------------------------------------------'
  end

  def candidate_tags(entry, title_tag_names, tag_id: nil, include_entities: true)
    tags = title_tag_names + extracted_tags(entry, tag_id:)
    include_entities ? tags + entity_tags(entry) : tags
  end

  def extracted_title_tags(entry, tag_id: nil)
    result = WebExtractorServices::ExtractTitleTags.call(entry.id, tag_id)
    result.success? ? Array(result.data) : []
  end

  def extracted_tags(entry, tag_id: nil)
    result = WebExtractorServices::ExtractTags.call(entry.id, tag_id)
    result.success? ? Array(result.data) : []
  end

  def entity_tags(entry)
    entry.entities.to_s.split(',')
  end

  def normalize_tags(tags)
    TagSanitizer.call(tags.flatten)
  end

  def apply_tags(entry, tags, replace:)
    replace ? entry.tag_list = tags : entry.tag_list.add(tags)
  end

  def apply_title_tags(entry, title_tags, replace:)
    return if title_tags.blank?

    replace ? entry.title_tag_list = title_tags : entry.title_tag_list.add(title_tags)
  end

  def selected_tag
    return Tag.find(ENV.fetch('TAG_ID')) if ENV['TAG_ID'].present?
    return Tag.friendly.find(ENV.fetch('TAG')) if ENV['TAG'].present?

    raise ArgumentError, 'Set TAG_ID=123 or TAG=tag-slug'
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
              .where.missing(:taggings)
              .limit(TaggerTask.limit)

    TaggerTask.tag_entries(entries)
  end

  desc 'Apply one tag to matching entries. Set TAG_ID=123 or TAG=tag-slug; set LIMIT=500 to control batch size.'
  task tag: :environment do
    tag = TaggerTask.selected_tag
    entries = Entry.tagger_scope.limit(TaggerTask.limit)

    TaggerTask.tag_entries(entries, tag_id: tag.id, include_entities: false, replace: false)
  end
end
