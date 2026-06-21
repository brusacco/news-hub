# frozen_string_literal: true

class GenresController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    @pagy, @genres = pagy(Genre.left_joins(:game_genres).select('genres.*, COUNT(game_genres.id) AS local_games_count')
                               .group(:id).order(:name), limit: INDEX_LIMIT)

    set_default_meta_tags(
      title: 'Nintendo Switch Game Genres - Browse Switch Games by Category',
      description: 'Browse Nintendo Switch games by genre, including action, adventure, RPG, strategy, platformer, ' \
                   'racing, sports, and more game categories.',
      keywords: 'Nintendo Switch genres, Switch games by genre, Nintendo Switch categories, game genres',
      canonical: genres_url,
      og: {
        title: 'Nintendo Switch Game Genres - Browse Switch Games by Category',
        description: 'Browse Nintendo Switch games by genre and category.',
        type: 'website',
        url: genres_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo Switch Game Genres - Browse Switch Games by Category',
        description: 'Browse Nintendo Switch games by genre and category.'
      }
    )
  end

  def show
    @genre = Genre.find_by!(slug: params[:id])
    @pagy, @games = pagy(@genre.games.includes(:genres).recent, limit: INDEX_LIMIT)

    title = "#{@genre.name} Nintendo Switch Games - Releases, Ratings & Details"
    description = genre_description(@genre, @pagy.count)

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

  private

  def genre_description(genre, game_count)
    count_text = game_count.positive? ? "#{game_count} " : ''

    "Browse #{count_text}#{genre.name} Nintendo Switch games with release dates, images, Metacritic scores, " \
      'and related game genres.'
  end
end
