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

  # Add an array of most used browsers
  browsers = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPad; CPU OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1'
  ]

  Site.find_each do |site|
    puts "Start test processing site #{site.name}..."
    puts '--------------------------------------------------------------------"'

    # Select a random user agent
    random_user_agent = browsers.sample

    Anemone.crawl(
      site.url,
      read_timeout: 10,
      depth_limit: site.crawl_deep,
      discard_page_bodies: true,
      accept_cookies: true,
      threads: 2,
      verbose: true,
      user_agent: random_user_agent
    ) do |anemone|
      anemone.skip_links_like(/.*\.(jpeg|jpg|gif|png|pdf|mp3|mp4|mpeg)/, directory_pattern, /[\?#].+/)

      anemone.focus_crawl do |page|
        page.links.delete_if { |href| Entry.exists?(source_url: href.to_s) }
      end

      anemone.on_pages_like(/#{site.url_filter}/) do |page|
        Entry.create_with(site: site).find_or_create_by!(source_url: page.url.to_s) do |entry|
          puts page.url.to_s.colorize(:green)

          #---------------------------------------------------------------------------
          # Basic data extractor
          #---------------------------------------------------------------------------
          result = WebExtractorServices::ExtractBasicInfo.call(page.doc)
          if result.success?
            entry.update!(result.data)
          else
            puts "ERROR BASIC: #{result.error}"
          end

          #---------------------------------------------------------------------------
          # Date extractor
          #---------------------------------------------------------------------------
          result = WebExtractorServices::ExtractDate.call(page.doc)
          if result.success?
            entry.update!(result.data)
            puts result.data
          else
            puts "ERROR DATE: #{result&.error}"
          end

        end
      rescue StandardError => e
        puts "Error processing page #{page.url}: #{e.message}".colorize(:red)
        next
      end
    end
  end
end
