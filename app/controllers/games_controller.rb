# frozen_string_literal: true

class GamesController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    @pagy, @games = pagy(Game.includes(:genres).recent, limit: INDEX_LIMIT)

    set_default_meta_tags(
      title: 'Nintendo Switch Games - Release Dates, Ratings & Details',
      description: 'Browse Nintendo Switch games imported from RAWG, including release dates, ratings, images, ' \
                   'and metadata.',
      keywords: 'Nintendo Switch games, Switch game releases, Nintendo games database, RAWG Nintendo Switch',
      canonical: games_url,
      og: {
        title: 'Nintendo Switch Games - Release Dates, Ratings & Details',
        description: 'Browse Nintendo Switch games with release dates, ratings, images, and metadata.',
        type: 'website',
        url: games_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo Switch Games - Release Dates, Ratings & Details',
        description: 'Browse Nintendo Switch games with release dates, ratings, images, and metadata.'
      }
    )
  end

  def show
    @game = Game.includes(:genres, :screenshots).find_by!(slug: params[:id])
    @related_games = related_games(@game)
    @related_entries = related_entries(@game)

    title = game_meta_title(@game)
    description = game_description(@game)

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: game_keywords(@game),
      canonical: game_url(@game),
      og: {
        title: title,
        description: description,
        type: 'website',
        url: game_url(@game),
        image: @game.background_image
      },
      twitter: {
        card: @game.background_image.present? ? 'summary_large_image' : 'summary',
        title: title,
        description: description,
        image: @game.background_image
      }
    )
  end

  private

  def related_games(game)
    return Game.none if game.genre_ids.blank?

    Game
      .joins(:game_genres)
      .where(game_genres: { genre_id: game.genre_ids })
      .where.not(id: game.id)
      .includes(:genres)
      .distinct
      .recent
      .limit(8)
  end

  def related_entries(game)
    game.entries
        .includes(:tags, :site)
        .where.not(published_at: nil)
        .recent
        .limit(8)
  end

  def game_meta_title(game)
    release_year = game.released&.year
    title_parts = [game.name, 'Nintendo Switch Game']
    title_parts << release_year if release_year.present?

    title_parts.join(' - ')
  end

  def game_description(game)
    details = ["#{game.name} Nintendo Switch game details"]
    details << "release date #{formatted_release_date(game)}" if game.released.present?
    details << "Metacritic score #{game.metacritic}" if game.metacritic.present?
    details << "genres #{game.genres.map(&:name).to_sentence}" if game.genres.any?

    "#{details.to_sentence}."
  end

  def formatted_release_date(game)
    game.released.strftime('%B %d, %Y')
  end

  def game_keywords(game)
    (
      [game.name, "#{game.name} Nintendo Switch", "#{game.name} game", "#{game.name} release date"] +
        game.genres.map { |genre| "#{genre.name} Nintendo Switch games" }
    ).compact.join(', ')
  end
end
