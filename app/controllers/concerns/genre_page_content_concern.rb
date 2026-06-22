# frozen_string_literal: true

module GenrePageContentConcern
  extend ActiveSupport::Concern

  MIN_INDEXABLE_GAMES = 3
  MIN_DESCRIPTION_LENGTH = 220

  private

  def top_developers(genre)
    Developer
      .joins(games: :genres)
      .where(genres: { id: genre.id })
      .distinct
      .order(games_count: :desc, name: :asc)
      .limit(6)
  end

  def indexable_genre_page?(genre, game_count = genre.games.count)
    game_count >= MIN_INDEXABLE_GAMES || rich_description?(genre.description)
  end

  def genre_supporting_copy(genre, featured_games, top_developers)
    return [] unless description_needs_enhancement?(genre.description)

    game_names = featured_games.map(&:name)
    developer_names = top_developers.map(&:name)

    [
      genre_intro_copy(genre.name),
      supporting_copy_details(genre.name, game_names, developer_names)
    ]
  end

  def genre_intro_copy(genre_name)
    "#{genre_name} is an important Nintendo Switch category for players looking to compare standout releases in one " \
      'place. This page brings together the most popular games first, so users can quickly find the titles that draw ' \
      'the most interest and coverage.'
  end

  def supporting_copy_details(genre_name, game_names, developer_names)
    details = ["Visitors can use this page to explore Nintendo Switch #{genre_name.downcase} games"]
    details << "such as #{game_names.to_sentence}" if game_names.any?
    details << "and discover developers like #{developer_names.to_sentence}" if developer_names.any?

    "#{details.to_sentence}."
  end

  def description_needs_enhancement?(description)
    !rich_description?(description)
  end

  def rich_description?(description)
    ActionController::Base.helpers.strip_tags(description.to_s).squish.length >= MIN_DESCRIPTION_LENGTH
  end
end
