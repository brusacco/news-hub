# frozen_string_literal: true

class GenresController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    @pagy, @genres = pagy(Genre.left_joins(:game_genres).select('genres.*, COUNT(game_genres.id) AS local_games_count')
                               .group(:id).order(:name), limit: INDEX_LIMIT)

    set_default_meta_tags(
      title: 'Nintendo Switch Game Genres - Browse Games by Genre',
      description: 'Browse Nintendo Switch game genres imported from RAWG and explore how many games are available ' \
                   'in each category.',
      keywords: 'Nintendo Switch genres, game genres, Nintendo games database, RAWG genres',
      canonical: genres_url,
      og: {
        title: 'Nintendo Switch Game Genres - Browse Games by Genre',
        description: 'Browse Nintendo Switch game genres and game counts.',
        type: 'website',
        url: genres_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo Switch Game Genres - Browse Games by Genre',
        description: 'Browse Nintendo Switch game genres and game counts.'
      }
    )
  end

  def show
    @genre = Genre.find_by!(slug: params[:id])
    @pagy, @games = pagy(@genre.games.includes(:genres).recent, limit: INDEX_LIMIT)

    title = "#{@genre.name} Nintendo Switch Games - Browse Games by Genre"
    description = "Browse Nintendo Switch games in the #{@genre.name} genre. Explore release dates, ratings, " \
                  'images, and metadata for games imported from RAWG.'

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: "#{@genre.name} Nintendo Switch games, #{@genre.name} games, Nintendo game genres",
      canonical: genre_url(@genre),
      og: {
        title: title,
        description: description,
        type: 'website',
        url: genre_url(@genre)
      },
      twitter: {
        card: 'summary_large_image',
        title: title,
        description: description
      }
    )
  end
end
