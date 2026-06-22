# frozen_string_literal: true

class GameMatcher < ApplicationService
  CompiledGame = Struct.new(:id, :name, :term, :pattern, :content_matchable, keyword_init: true)
  Match = Struct.new(:game_id, :game_name, :match_source, :confidence, :matched_text, keyword_init: true)

  SOURCE_WEIGHTS = {
    title: 100,
    ai_title: 95,
    title_tags: 90,
    tags: 75,
    description: 65,
    ai_description: 65,
    summary: 55,
    ai_summary: 55,
    content: 45
  }.freeze
  STRICT_SOURCES = %i[title ai_title title_tags tags].freeze
  MIN_CONTENT_MATCH_LENGTH = 4

  def self.compile(games)
    games.flat_map { |game| compiled_terms_for(game) }
  end

  def self.link_entry!(entry, games: Game.includes(:name_tags), compiled_games: nil, replace: true)
    matcher = new(entry, games:, compiled_games:)
    matches = matcher.matches

    EntryGame.transaction do
      entry.entry_games.where.not(game_id: matches.map(&:game_id)).delete_all if replace
      matches.each { |match| upsert_entry_game(entry, match) }
    end

    matches
  end

  def self.compiled_terms_for(game)
    terms_for(game).map do |term|
      CompiledGame.new(
        id: game.id,
        name: game.name,
        term: term,
        pattern: /(^|[^\p{Alnum}_])#{Regexp.escape(term)}(?=$|[^\p{Alnum}_])/i,
        content_matchable: term.gsub(/[^\p{Alnum}]+/, '').length >= MIN_CONTENT_MATCH_LENGTH
      )
    end
  end

  def self.terms_for(game)
    [game.name, game.name_tags.map(&:name)].flatten.filter_map { |term| term.to_s.strip.presence }.uniq
  end

  def self.upsert_entry_game(entry, match)
    entry.entry_games.find_or_initialize_by(game_id: match.game_id).tap do |entry_game|
      entry_game.assign_attributes(
        match_source: match.match_source,
        confidence: match.confidence,
        matched_text: match.matched_text
      )
      entry_game.save!
    end
  end

  def initialize(entry, games: Game.includes(:name_tags), compiled_games: nil)
    @entry = entry
    @compiled_games = compiled_games || self.class.compile(games)
  end

  def matches
    @matches ||= best_matches.values.sort_by { |match| [-match.confidence, match.game_name] }
  end

  private

  def best_matches
    searchable_sources.each_with_object({}) do |(source, content), found|
      next if content.blank?

      match_source(source, content, found)
    end
  end

  def match_source(source, content, found)
    @compiled_games.each do |game|
      next unless source_allows_game?(source, game)
      next unless content.match?(game.pattern)

      match = build_match(game, source)
      found[game.id] = strongest_match(found[game.id], match)
    end
  end

  def source_allows_game?(source, game) = STRICT_SOURCES.include?(source) || game.content_matchable

  def build_match(game, source)
    Match.new(
      game_id: game.id,
      game_name: game.name,
      match_source: source.to_s,
      confidence: SOURCE_WEIGHTS.fetch(source),
      matched_text: game.term
    )
  end

  def strongest_match(current_match, next_match)
    current_match.blank? || next_match.confidence > current_match.confidence ? next_match : current_match
  end

  def searchable_sources
    [
      [:title, @entry.title],
      [:ai_title, @entry.ai_title],
      [:title_tags, @entry.title_tags.map(&:name).join(' ')],
      [:tags, @entry.tags.map(&:name).join(' ')],
      [:description, @entry.description],
      [:ai_description, @entry.ai_description],
      [:summary, @entry.summary],
      [:ai_summary, @entry.ai_summary],
      [:content, @entry.content]
    ]
  end
end
