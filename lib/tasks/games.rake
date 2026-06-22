# frozen_string_literal: true

module GameLinkerTask
  DEFAULT_LIMIT = 500

  module_function

  def limit
    return nil if ENV.fetch('LIMIT', DEFAULT_LIMIT).to_s.casecmp('all').zero?

    value = ENV.fetch('LIMIT', DEFAULT_LIMIT).to_i
    value.positive? ? value : DEFAULT_LIMIT
  end

  def limit_scope(scope)
    limit ? scope.limit(limit) : scope
  end

  def link_entries(entries, game_id: nil, replace: true)
    matcher_context = build_matcher_context(game_id)

    entries.includes(:tags, :title_tags).find_each do |entry|
      matches = GameMatcher.link_entry!(entry, replace:, **matcher_context)
      log_linked_entry(entry, matches)
    rescue StandardError => e
      puts "Skipping entry #{entry.id}: #{e.message}"
    end
  end

  def build_matcher_context(game_id = nil)
    games = matching_games(game_id).load

    {
      games: games,
      compiled_games: GameMatcher.compile(games)
    }
  end

  def matching_games(game_id = nil)
    scope = Game.includes(:name_tags)
    game_id.present? ? scope.where(id: game_id) : scope
  end

  def selected_entry
    Entry.find(ENV.fetch('ENTRY_ID'))
  end

  def selected_game
    return Game.find(ENV.fetch('GAME_ID')) if ENV['GAME_ID'].present?
    return Game.find_by!(slug: ENV.fetch('GAME')) if ENV['GAME'].present?

    nil
  end

  def entries_scope
    ENV['ALL'].present? ? Entry.recent : Entry.tagger_scope
  end

  def log_linked_entry(entry, matches)
    return if matches.blank?

    puts entry.source_url
    puts "Games: #{matches.map(&:game_name).join(', ')}"
    puts '---------------------------------------------------'
  end

  def populate_name_tags(scope, force: false)
    scope.find_each do |game|
      next if game.name_tag_list.present? && !force

      game.name_tag_list = [Game.default_name_tag_for(game.name)]
      game.save!
      puts "#{game.id}: #{game.name} -> #{game.name_tag_list.join(', ')}"
    end
  end
end

namespace :games do
  desc 'Populate game name_tags. Set FORCE=true to overwrite existing values; LIMIT=all for no cap.'
  task populate_name_tags: :environment do
    GameLinkerTask.populate_name_tags(
      GameLinkerTask.limit_scope(Game.order(:id)),
      force: ENV.fetch('FORCE', 'false') == 'true'
    )
  end
end

namespace :games do
  desc 'Populate one game name_tags list. Set GAME_ID=123 or GAME=slug; FORCE=true overwrites existing value.'
  task populate_name_tag: :environment do
    game = GameLinkerTask.selected_game || raise(ArgumentError, 'Set GAME_ID=123 or GAME=slug')

    GameLinkerTask.populate_name_tags(
      Game.where(id: game.id),
      force: ENV.fetch('FORCE', 'false') == 'true'
    )
  end
end

namespace :games do
  desc 'Link entries to games. Set LIMIT=500, LIMIT=all, GAME_ID=123, GAME=slug, or ALL=true.'
  task link_entries: :environment do
    game = GameLinkerTask.selected_game
    entries = GameLinkerTask.limit_scope(GameLinkerTask.entries_scope)

    GameLinkerTask.link_entries(entries, game_id: game&.id, replace: game.blank?)
  end
end

namespace :games do
  desc 'Link one entry to games. Set ENTRY_ID=123; optionally GAME_ID=123 or GAME=slug.'
  task link_entry: :environment do
    game = GameLinkerTask.selected_game

    GameMatcher.link_entry!(
      GameLinkerTask.selected_entry,
      replace: game.blank?,
      **GameLinkerTask.build_matcher_context(game&.id)
    )
  end
end

namespace :games do
  desc 'Delete entry-game links. Dry-run by default; set DRY_RUN=false to delete.'
  task cleanup_entry_links: :environment do
    count = EntryGame.count
    puts "Found #{count} entry-game links"

    if ENV.fetch('DRY_RUN', 'true') == 'false'
      EntryGame.delete_all
      puts "Deleted #{count} entry-game links"
    else
      puts 'Dry run only. Set DRY_RUN=false to delete these links.'
    end
  end
end
