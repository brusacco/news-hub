# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://www.nintendonewshub.com'

# rubocop:disable Metrics/BlockLength
SitemapGenerator::Sitemap.create do
  rich_description = lambda do |text|
    ActionController::Base.helpers.strip_tags(text.to_s).squish.length >= 220
  end

  indexable_genre = lambda do |genre|
    genre.games.limit(3).count >= 3 || rich_description.call(genre.description)
  end

  indexable_developer = lambda do |developer|
    developer.games.limit(3).count >= 3 || rich_description.call(developer.description)
  end

  indexable_tag = lambda do |tag|
    tag.taggings_count.to_i >= 3
  end

  tag_lastmod = lambda do |tag|
    tagged_entries_updated_at = Entry.tagged_with(tag.name, on: :tags).maximum(:updated_at)
    [tag.updated_at, tagged_entries_updated_at].compact.max
  end

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  add entries_path, priority: 0.9, changefreq: 'hourly'
  add games_path, priority: 0.8, changefreq: 'daily'
  add genres_path, priority: 0.7, changefreq: 'weekly'
  add developers_path, priority: 0.7, changefreq: 'weekly'
  add tags_path, priority: 0.75, changefreq: 'daily'

  Game.find_each do |game|
    add game_path(game), lastmod: game.updated_at, priority: 0.75, changefreq: 'weekly'
  end

  Genre.find_each do |genre|
    next unless indexable_genre.call(genre)

    add genre_path(genre), lastmod: genre.updated_at, priority: 0.65, changefreq: 'weekly'
  end

  Developer.find_each do |developer|
    next unless indexable_developer.call(developer)

    add developer_path(developer), lastmod: developer.updated_at, priority: 0.65, changefreq: 'weekly'
  end

  Tag.find_each do |tag|
    next unless indexable_tag.call(tag)

    add tag_path(tag), lastmod: tag_lastmod.call(tag), changefreq: 'daily', priority: 0.7
  end
  #
  # Add all articles:
  #
  Entry.find_each do |entry|
    add entry_path(entry), lastmod: entry.updated_at, priority: 0.95, changefreq: 'daily'
  end
end
# rubocop:enable Metrics/BlockLength
