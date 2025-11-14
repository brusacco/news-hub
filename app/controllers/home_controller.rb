# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  def index
    @entries = Entry.recent.includes(:tags, :site)
    @pagy, @entries = pagy(@entries, limit: 60)

    set_default_meta_tags(
      title: 'Nintendo News Hub - Latest Nintendo News & Updates',
      description: 'Stay updated with the latest Nintendo news, game releases, and updates. Your trusted source for Nintendo Switch, games, and gaming industry insights.',
      keywords: 'Nintendo news, Nintendo Switch, Nintendo games, gaming news, Nintendo updates',
      canonical: root_url,
      og: {
        title: 'Nintendo News Hub - Latest Nintendo News & Updates',
        description: 'Stay updated with the latest Nintendo news, game releases, and updates. Your trusted source for Nintendo Switch, games, and gaming industry insights.',
        type: 'website',
        url: root_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Nintendo News Hub - Latest Nintendo News & Updates',
        description: 'Stay updated with the latest Nintendo news, game releases, and updates.'
      }
    )
  end

  def trending
    @entries = Entry.a_day_ago.includes(:tags, :site).order(total_count: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)

    set_default_meta_tags(
      title: 'Trending Nintendo News - Popular Articles Today',
      description: 'Discover the most popular and trending Nintendo news articles from the last 24 hours. See what the Nintendo community is talking about.',
      keywords: 'trending Nintendo news, popular Nintendo articles, Nintendo trending topics',
      canonical: trending_url,
      og: {
        title: 'Trending Nintendo News - Popular Articles Today',
        description: 'Discover the most popular and trending Nintendo news articles from the last 24 hours.',
        type: 'website',
        url: trending_url
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Trending Nintendo News - Popular Articles Today',
        description: 'Discover the most popular and trending Nintendo news articles from the last 24 hours.'
      }
    )
  end

  def who
    set_default_meta_tags(
      title: 'About Us - Nintendo News Hub',
      description: 'Learn about Nintendo News Hub, your trusted source for Nintendo news, updates, and insights. Discover our mission and data-driven approach to gaming journalism.',
      keywords: 'about Nintendo News Hub, Nintendo news source, gaming journalism',
      canonical: who_url,
      og: {
        title: 'About Us - Nintendo News Hub',
        description: 'Learn about Nintendo News Hub, your trusted source for Nintendo news, updates, and insights.',
        url: who_url
      }
    )
  end

  def terms
    set_default_meta_tags(
      title: 'Terms of Service - Nintendo News Hub',
      description: 'Read the Terms of Service for Nintendo News Hub. Understand our terms and conditions for using our Nintendo news platform.',
      keywords: 'terms of service, Nintendo News Hub terms',
      canonical: terms_url,
      robots: 'noindex, follow',
      og: {
        title: 'Terms of Service - Nintendo News Hub',
        description: 'Read the Terms of Service for Nintendo News Hub.',
        url: terms_url
      }
    )
  end

  def privacy
    set_default_meta_tags(
      title: 'Privacy Policy - Nintendo News Hub',
      description: 'Read our Privacy Policy to understand how Nintendo News Hub collects, uses, and protects your information when you visit our site.',
      keywords: 'privacy policy, Nintendo News Hub privacy',
      canonical: privacy_url,
      robots: 'noindex, follow',
      og: {
        title: 'Privacy Policy - Nintendo News Hub',
        description: 'Read our Privacy Policy to understand how Nintendo News Hub collects, uses, and protects your information.',
        url: privacy_url
      }
    )
  end

  def search
    @keyword = params[:keyword]
    @entries = EntrySearchService.new(@keyword).call
    @pagy, @entries = pagy(@entries, limit: 60)

    title_text = @keyword.present? ? "Search: #{@keyword} - Nintendo News" : 'Search Nintendo News'
    description_text = @keyword.present? ? "Search results for '#{@keyword}' on Nintendo News Hub. Find the latest Nintendo news, articles, and updates." : 'Search Nintendo News Hub for the latest articles, news, and updates.'

    set_default_meta_tags(
      title: title_text,
      description: description_text,
      keywords: @keyword.present? ? "#{@keyword}, Nintendo news, Nintendo search" : 'Nintendo news search',
      canonical: search_url(keyword: @keyword),
      robots: 'noindex, follow',
      og: {
        title: title_text,
        description: description_text,
        type: 'website',
        url: search_url(keyword: @keyword)
      },
      twitter: {
        card: 'summary',
        title: title_text,
        description: description_text
      }
    )
  end

  def search_autocomplete
    results = AutocompleteSearchService.new(params[:q]).call
    render json: results
  end
end
