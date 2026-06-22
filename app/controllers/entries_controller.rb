# frozen_string_literal: true

class EntriesController < ApplicationController
  include EntryMetaTagsConcern
  include Pagy::Backend
  include EntryRelatedContentConcern
  include MetaTagsConcern

  INDEX_LIMIT = 60

  def index
    entries = Entry.recent.includes(:tags, :site)
    @pagy, @entries = pagy(entries, limit: INDEX_LIMIT)

    set_default_meta_tags(
      title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
      description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles, game updates, and ' \
                   'platform announcements.',
      keywords: 'Nintendo news archive, Nintendo updates, Nintendo Switch news, gaming news',
      canonical: entries_url,
      og: {
        title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
        description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles, game updates, and ' \
                     'platform announcements.',
        type: 'website',
        url: entries_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo News Archive - Latest Nintendo Articles & Updates',
        description: 'Browse the Nintendo News Hub archive for the latest Nintendo articles and platform announcements.'
      }
    )
  end

  def show
    @entry = Entry.with_tags.with_site.friendly.find(params[:id])
    @entries = find_related_entries
    @games = related_games
    set_entry_meta_tags
  end
end
