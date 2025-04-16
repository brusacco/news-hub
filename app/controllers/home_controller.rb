# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)

    set_meta_tags title: 'Nintendo News Hub',
                  description: 'Best Nintendo News Aggregator',
                  keywords: 'Nintendo, News, Aggregator, Switch, Wii U',
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: root_url
                    # image: view_context.asset_url('images/Rostra-Powertrain-Controls-logo.png')
                  },
                  twitter: { card: 'summary' }
  end

  def trending
    @entries = Entry.a_week_ago.order(total_count: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end
end
