# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)

    set_meta_tags title: 'Nintendo News Hub',
                  description: 'Best Nintendo News Online',
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
    @entries = Entry.a_day_ago.order(total_count: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end

  def who
  end

  def terms
  end

  def privacy
  end

  def search
    @keyword = params[:keyword]
    @entries = if @keyword.present?
                 Entry.where('LOWER(title) LIKE :keyword OR LOWER(description) LIKE :keyword',
                             keyword: "%#{@keyword.downcase}%")
                      .order(published_at: :desc)
               else
                 Entry.none
               end

    @pagy, @entries = pagy(@entries, limit: 60)

    set_meta_tags title: "Search results for '#{@keyword}'",
                  description: "Search results for '#{@keyword}' on Nintendo News Hub",
                  keywords: @keyword,
                  og: {
                    title: :title,
                    description: :description,
                    site_name: 'NintendoNewsHub.com',
                    type: 'website',
                    url: search_url(keyword: @keyword)
                  },
                  twitter: { card: 'summary' }
  end
end
