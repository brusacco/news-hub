# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://www.nintendonewshub.com'

SitemapGenerator::Sitemap.create do
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
  add games_path, priority: 0.8, changefreq: 'daily'
  add genres_path, priority: 0.7, changefreq: 'daily'
  add developers_path, priority: 0.7, changefreq: 'daily'
  add tags_path, priority: 0.7, changefreq: 'daily'

  Game.find_each do |game|
    add game_path(game), lastmod: game.updated_at, priority: 0.8, changefreq: 'weekly'
  end

  Genre.find_each do |genre|
    add genre_path(genre), lastmod: genre.updated_at, priority: 0.7, changefreq: 'weekly'
  end

  Developer.find_each do |developer|
    add developer_path(developer), lastmod: developer.updated_at, priority: 0.7, changefreq: 'weekly'
  end

  Tag.find_each do |tag|
    add tag_path(tag), lastmod: Time.zone.now, changefreq: 'daily', priority: 0.8
  end
  #
  # Add all articles:
  #
  Entry.find_each do |entry|
    add entry_path(entry), lastmod: entry.updated_at, priority: 1.0, changefreq: 'daily'
  end
end
