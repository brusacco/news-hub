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
end
