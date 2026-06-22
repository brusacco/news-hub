# frozen_string_literal: true

class DevelopersController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    @pagy, @developers = pagy(
      Developer.left_joins(:game_developers)
               .select('developers.*, COUNT(game_developers.id) AS local_games_count')
               .group(:id)
               .order(games_count: :desc, name: :asc),
      limit: INDEX_LIMIT
    )

    set_default_meta_tags(
      title: 'Nintendo Switch Game Developers - Browse Studios and Teams',
      description: 'Browse Nintendo Switch game developers and studios, then explore the games imported for each team.',
      keywords: 'Nintendo Switch developers, Switch game studios, Nintendo game developers, RAWG developers',
      canonical: developers_url,
      og: {
        title: 'Nintendo Switch Game Developers - Browse Studios and Teams',
        description: 'Browse Nintendo Switch game developers and studios.',
        type: 'website',
        url: developers_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo Switch Game Developers - Browse Studios and Teams',
        description: 'Browse Nintendo Switch game developers and studios.'
      }
    )
  end

  def show
    @developer = Developer.find_by!(slug: params[:id])
    @pagy, @games = pagy(@developer.games.includes(:genres, :developers).popular_first, limit: INDEX_LIMIT)
    @related_entries = related_entries(@developer)

    set_default_meta_tags(developer_meta_tags(@developer, @pagy.count))
  end

  private

  def related_entries(developer)
    return Entry.none if developer.game_ids.blank?

    Entry
      .joins(:entry_games)
      .where(entry_games: { game_id: developer.game_ids })
      .includes(:tags, :site)
      .distinct
      .recent
      .limit(6)
  end

  def developer_meta_tags(developer, game_count)
    title = "#{developer.name} Nintendo Switch Games - Releases, Ratings & Details"
    description = developer_description(developer, game_count)

    {
      title: title,
      description: description,
      keywords: "#{developer.name} Nintendo Switch games, #{developer.name} games, Nintendo Switch developers",
      canonical: developer_url(developer),
      robots: game_count.positive? ? 'index, follow' : 'noindex, follow',
      og: {
        title: title,
        description: description,
        type: 'website',
        url: developer_url(developer),
        image: developer.image_background
      },
      twitter: {
        card: developer.image_background.present? ? 'summary_large_image' : 'summary',
        title: title,
        description: description,
        image: developer.image_background
      }
    }
  end

  def developer_description(developer, game_count)
    count_text = game_count.positive? ? "#{game_count} " : ''

    "Browse #{count_text}Nintendo Switch games by #{developer.name}, with ratings, images, genres, " \
      'and related news coverage.'
  end
end
