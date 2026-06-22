# frozen_string_literal: true

class GenresController < ApplicationController
  include Pagy::Backend
  include GenrePageContentConcern
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
    load_genre_page_data

    set_default_meta_tags(genre_meta_tags(@genre, @pagy.count))
  end

  private

  def load_genre_page_data
    @pagy, @games = pagy(@genre.games.includes(:genres).popular_first, limit: INDEX_LIMIT)
    @related_entries = related_entries(@genre)
    @top_developers = top_developers(@genre)
    @genre_supporting_copy = genre_supporting_copy(@genre, @games.to_a.first(3), @top_developers)
    @matching_tag = matching_tag(@genre.name)
  end

  def related_entries(genre)
    return Entry.none if genre.game_ids.blank?

    Entry
      .joins(:entry_games)
      .where(entry_games: { game_id: genre.game_ids })
      .includes(:tags, :site)
      .distinct
      .recent
      .limit(6)
  end

  def genre_meta_tags(genre, game_count)
    title = "#{genre.name} Nintendo Switch Games - Releases, Ratings & Details"
    description = genre_description(genre, game_count)

    {
      title: title,
      description: description,
      keywords: "#{genre.name} Nintendo Switch games, #{genre.name} games, Nintendo game genres",
      canonical: genre_url(genre),
      robots: indexable_genre_page?(genre, game_count) ? 'index, follow' : 'noindex, follow',
      og: genre_open_graph_tags(genre, title, description),
      twitter: genre_twitter_tags(genre, title, description)
    }
  end

  def genre_open_graph_tags(genre, title, description)
    {
      title: title,
      description: description,
      type: 'website',
      url: genre_url(genre),
      image: genre.image_background
    }
  end

  def genre_twitter_tags(genre, title, description)
    {
      card: 'summary_large_image',
      title: title,
      description: description,
      image: genre.image_background
    }
  end

  def genre_description(genre, game_count)
    count_text = game_count.positive? ? "#{game_count} " : ''

    "Browse #{count_text}#{genre.name} Nintendo Switch games with ratings, images, Metacritic scores, " \
      'and related game genres.'
  end

  def matching_tag(name)
    Tag.find_by('LOWER(name) = ?', name.downcase)
  end
end
