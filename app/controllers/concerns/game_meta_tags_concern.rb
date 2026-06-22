# frozen_string_literal: true

module GameMetaTagsConcern
  extend ActiveSupport::Concern

  private

  def game_meta_title(game)
    release_year = game.released&.year
    title_parts = [game.name, 'Nintendo Switch Game']
    title_parts << release_year if release_year.present?

    title_parts.join(' - ')
  end

  def game_description(game)
    "#{game_description_parts(game).to_sentence}."
  end

  def game_keywords(game)
    (
      [game.name, "#{game.name} Nintendo Switch", "#{game.name} game", "#{game.name} release date"] +
        game.genres.map { |genre| "#{genre.name} Nintendo Switch games" } +
        game.developers.map { |developer| "#{developer.name} Nintendo Switch games" }
    ).compact.join(', ')
  end

  def game_description_parts(game)
    [
      "#{game.name} Nintendo Switch game details",
      game_release_detail(game),
      game_metacritic_detail(game),
      game_genres_detail(game),
      game_developers_detail(game)
    ].compact
  end

  def game_release_detail(game)
    "release date #{formatted_release_date(game)}" if game.released.present?
  end

  def game_metacritic_detail(game)
    "Metacritic score #{game.metacritic}" if game.metacritic.present?
  end

  def game_genres_detail(game)
    "genres #{game.genres.map(&:name).to_sentence}" if game.genres.any?
  end

  def game_developers_detail(game)
    "developer #{game.developers.map(&:name).to_sentence}" if game.developers.any?
  end

  def formatted_release_date(game)
    game.released.strftime('%B %d, %Y')
  end
end
