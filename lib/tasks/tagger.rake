# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module TaggerTask
  DEFAULT_LIMIT = 100
  MAX_RETRIES = 3

  module_function

  def limit
    return nil if ENV.fetch('LIMIT', DEFAULT_LIMIT).to_s.casecmp('all').zero?

    value = ENV.fetch('LIMIT', DEFAULT_LIMIT).to_i
    value.positive? ? value : DEFAULT_LIMIT
  end

  def limit_scope(scope)
    limit ? scope.limit(limit) : scope
  end

  def tag_entries(entries, tag_id: nil, include_entities: true, replace: true)
    matcher_context = build_matcher_context(tag_id)
    game_matcher_context = build_game_matcher_context

    entries.each do |entry|
      retries = 0

      begin
        tag_entry(
          entry,
          tag_id:,
          include_entities:,
          replace:,
          contexts: matcher_contexts(matcher_context, game_matcher_context)
        )
      rescue StandardError => e
        retries += 1
        puts e.message

        if retries <= MAX_RETRIES
          sleep 1
          retry
        end

        puts "Skipping entry #{entry.id} after #{MAX_RETRIES} retries"
      end
    end
  end

  def tag_title_entries(entries, tag_id: nil, replace: true)
    matcher_context = build_matcher_context(tag_id)
    game_matcher_context = build_game_matcher_context

    entries.each do |entry|
      retries = 0

      begin
        tag_title_entry(entry, tag_id:, replace:, matcher_context:, game_matcher_context:)
      rescue StandardError => e
        retries += 1
        puts e.message

        if retries <= MAX_RETRIES
          sleep 1
          retry
        end

        puts "Skipping entry #{entry.id} after #{MAX_RETRIES} retries"
      end
    end
  end

  def tag_entry(entry, tag_id: nil, include_entities: true, replace: true, contexts: {})
    matcher_context = contexts[:tags] || build_matcher_context(tag_id)
    game_matcher_context = contexts[:games] || build_game_matcher_context

    title_tag_names = normalize_tags(extracted_title_tags(entry, tag_id:, matcher_context:))
    tag_names = normalize_tags(
      candidate_tags(entry, title_tag_names, tag_id:, include_entities:, matcher_context:)
    )
    return link_games(entry, game_matcher_context:) if tag_names.blank?
    return link_games(entry, game_matcher_context:) unless apply_entry_tags(entry, tag_names, title_tag_names, replace:)

    entry.save!
    link_games(entry.reload, game_matcher_context:)
    log_tagged_entry(entry)
  end

  def matcher_contexts(matcher_context, game_matcher_context)
    {
      tags: matcher_context,
      games: game_matcher_context
    }
  end

  def tag_title_entry(entry, tag_id: nil, replace: true, matcher_context: nil, game_matcher_context: nil)
    matcher_context ||= build_matcher_context(tag_id)
    game_matcher_context ||= build_game_matcher_context

    title_tag_names = normalize_tags(extracted_title_tags(entry, tag_id:, matcher_context:))
    if title_tag_names.blank?
      link_games(entry, game_matcher_context:)
      return
    end

    unless apply_title_tags(entry, title_tag_names, replace:)
      link_games(entry, game_matcher_context:)
      return
    end

    entry.save!
    link_games(entry.reload, game_matcher_context:)
    log_tagged_entry(entry)
  end

  def log_tagged_entry(entry)
    puts entry.source_url
    puts entry.tag_list
    puts "Title tags: #{entry.title_tag_list.join(', ')}" if entry.title_tag_list.any?
    puts '---------------------------------------------------'
  end

  def candidate_tags(entry, title_tag_names, tag_id: nil, include_entities: true, matcher_context: nil)
    tags = title_tag_names + extracted_tags(entry, tag_id:, matcher_context:)
    include_entities ? tags + entity_tags(entry) : tags
  end

  def extracted_title_tags(entry, tag_id: nil, matcher_context: nil)
    matcher_context ||= build_matcher_context(tag_id)
    result = WebExtractorServices::ExtractTitleTags.call(entry, tag_id, **matcher_context)
    result.success? ? Array(result.data) : []
  end

  def extracted_tags(entry, tag_id: nil, matcher_context: nil)
    matcher_context ||= build_matcher_context(tag_id)
    result = WebExtractorServices::ExtractTags.call(entry, tag_id, **matcher_context)
    result.success? ? Array(result.data) : []
  end

  def entity_tags(entry)
    entry.entities.to_s.split(',')
  end

  def normalize_tags(tags)
    TagSanitizer.call(tags.flatten)
  end

  def apply_tags(entry, tags, replace:)
    return false if tags.blank?

    next_tags = replace ? tags : (entry.tag_list + tags).uniq
    return false if entry.tag_list == next_tags

    entry.tag_list = next_tags
    true
  end

  def apply_entry_tags(entry, tag_names, title_tag_names, replace:)
    changed = apply_tags(entry, tag_names, replace:)
    apply_title_tags(entry, title_tag_names, replace:) || changed
  end

  def apply_title_tags(entry, title_tags, replace:)
    return false if title_tags.blank?

    next_tags = replace ? title_tags : (entry.title_tag_list + title_tags).uniq
    return false if entry.title_tag_list == next_tags

    entry.title_tag_list = next_tags
    true
  end

  def build_matcher_context(tag_id = nil)
    tags = matching_tags(tag_id).load

    {
      tags: tags,
      compiled_tags: WebExtractorServices::TagMatcher.compile(tags)
    }
  end

  def build_game_matcher_context
    games = Game.includes(:name_tags).load

    {
      games: games,
      compiled_games: GameMatcher.compile(games)
    }
  end

  def link_games(entry, game_matcher_context:)
    GameMatcher.link_entry!(entry, **game_matcher_context)
  end

  def matching_tags(tag_id = nil)
    tag_id.nil? ? Tag.all : Tag.where(id: tag_id)
  end

  def entries_missing_title_tags
    Entry.tagger_scope.where(
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1
          FROM taggings
          WHERE taggings.taggable_type = 'Entry'
            AND taggings.taggable_id = entries.id
            AND taggings.context = 'title_tags'
        )
      SQL
    )
  end

  def selected_tag
    return Tag.find(ENV.fetch('TAG_ID')) if ENV['TAG_ID'].present?
    return Tag.friendly.find(ENV.fetch('TAG')) if ENV['TAG'].present?

    raise ArgumentError, 'Set TAG_ID=123 or TAG=tag-slug'
  end
end

desc 'Tagger'
task tagger: :environment do
  entries = TaggerTask.limit_scope(Entry.order(id: :desc))
  TaggerTask.tag_entries(entries)
end

namespace :tagger do
  desc 'Tag untagged entries. Set LIMIT=500 to control batch size.'
  task untagged: :environment do
    entries = Entry
              .tagger_scope
              .where.missing(:taggings)

    TaggerTask.tag_entries(TaggerTask.limit_scope(entries))
  end

  desc 'Backfill title_tags. Defaults to missing title_tags; set ALL=true to recompute all; LIMIT=all for no cap.'
  task title_tags: :environment do
    entries = ENV['ALL'].present? ? Entry.tagger_scope : TaggerTask.entries_missing_title_tags

    TaggerTask.tag_title_entries(TaggerTask.limit_scope(entries))
  end

  desc 'Apply one tag to matching entries. Set TAG_ID=123 or TAG=tag-slug; set LIMIT=500 to control batch size.'
  task tag: :environment do
    tag = TaggerTask.selected_tag
    entries = TaggerTask.limit_scope(Entry.tagger_scope)

    TaggerTask.tag_entries(entries, tag_id: tag.id, include_entities: false, replace: false)
  end
end
# rubocop:enable Metrics/ModuleLength
