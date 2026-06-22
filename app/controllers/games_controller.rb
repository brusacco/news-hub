# frozen_string_literal: true

class GamesController < ApplicationController
  include Pagy::Backend
  include GameMetaTagsConcern
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    @pagy, @games = pagy(Game.includes(:genres, :developers).popular_first, limit: INDEX_LIMIT)

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
    @game = Game.includes(:genres, :developers, :screenshots).find_by!(slug: params[:id])
    load_game_page_relations

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

  def load_game_page_relations
    @related_games = related_games(@game)
    @more_from_developers = more_from_developers(@game)
    @more_in_genres = more_in_genres(@game)
    @related_entries = related_entries(@game)
  end

  def related_games(game)
    return Game.none if game.genre_ids.blank?

    required_genre_ids = game.genre_ids.sort

    Game
      .joins(:game_genres)
      .where(game_genres: { genre_id: required_genre_ids })
      .where.not(id: game.id)
      .group('games.id')
      .having('COUNT(DISTINCT game_genres.genre_id) = ?', required_genre_ids.length)
      .includes(:genres)
      .order(ratings_count: :desc, rating: :desc, metacritic: :desc, released: :desc, name: :asc)
      .limit(8)
  end

  def related_entries(game)
    game.entries
        .includes(:tags, :site)
        .where.not(published_at: nil)
        .recent
        .limit(8)
  end

  def more_from_developers(game)
    return Game.none if game.developer_ids.blank?

    Game
      .joins(:developers)
      .where(developers: { id: game.developer_ids })
      .where.not(id: game.id)
      .includes(:genres, :developers)
      .distinct
      .popular_first
      .limit(8)
  end

  def more_in_genres(game)
    return Game.none if game.genre_ids.blank?

    Game
      .joins(:genres)
      .where(genres: { id: game.genre_ids })
      .where.not(id: game.id)
      .includes(:genres, :developers)
      .distinct
      .popular_first
      .limit(8)
  end
end
