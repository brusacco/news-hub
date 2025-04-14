# frozen_string_literal: true

desc 'Moopio Morfeo web crawler'
task crawler: :environment do
  directories = %w[
    blackhole
    wp-login
    wp-admin
    page
    category
    auth
    wp-content
    img
    tag
    date
    feed
    users
    games
    letter
    forum
    forums
    reviews
    features
    guides
  ]
  directory_pattern = /#{directories.join('|')}/
  Site.find_each do |site|
    puts "Start test processing site #{site.name}..."
    puts '--------------------------------------------------------------------"'
    Anemone.crawl(
      site.url,
      read_timeout: 10,
      depth_limit: 1,
      discard_page_bodies: true,
      accept_cookies: true,
      threads: 2,
      verbose: true,
      user_agent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3071.115 Safari/537.36'
    ) do |anemone|
      anemone.skip_links_like(/.*\.(jpeg|jpg|gif|png|pdf|mp3|mp4|mpeg)/, directory_pattern)

      anemone.on_pages_like(/#{site.url_filter}/) do |page|
        puts page.url.to_s.colorize(:green)
      end
    end
  end
end
