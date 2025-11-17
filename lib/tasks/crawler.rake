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
    game
    letter
    forum
    forums
    reviews
    features
    guides
    archive
    store
  ]
  directory_pattern = /#{directories.join('|')}/

  # Add an array of most used browsers
  browsers = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0'
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
      anemone.skip_links_like(/.*\.(jpeg|jpg|gif|png|pdf|mp3|mp4|mpeg)/, directory_pattern, /\S+\?\S+/)

      anemone.focus_crawl do |page|
        page.links.delete_if { |href| Entry.exists?(source_url: href.to_s) }
      end

      anemone.on_pages_like(/#{site.url_filter}/) do |page|
        entry = Entry.find_or_initialize_by(source_url: page.url.to_s)
        entry.site ||= site
        
        # Skip if entry already exists and has all required data
        if entry.persisted? && entry.published_at.present?
          puts "#{page.url.to_s} (skipped - already exists)".colorize(:yellow)
          next
        end
        
        puts page.url.to_s.colorize(:green)

        #---------------------------------------------------------------------------
        # Basic data extractor
        #---------------------------------------------------------------------------
        result = WebExtractorServices::ExtractBasicInfo.call(page.doc)
        if result.success?
          entry.assign_attributes(result.data)
        else
          puts "ERROR BASIC: #{result.error}"
        end

        #---------------------------------------------------------------------------
        # Date extractor
        #---------------------------------------------------------------------------
        result = WebExtractorServices::ExtractDate.call(page.doc)
        if result.success?
          entry.assign_attributes(result.data)
          puts result.data
        else
          puts "ERROR DATE: #{result&.error}"
          # Set default published_at if extraction failed
          entry.published_at ||= Time.current
        end

        #---------------------------------------------------------------------------
        # Content extractor
        #---------------------------------------------------------------------------
        result = WebExtractorServices::ArticleExtractor.call(page.url.to_s, page.doc.to_html)
        if result.success?
          entry.assign_attributes(result.data)
          puts result.data
        else
          puts "ERROR CONTENT: #{result&.error}"
        end

        # Ensure published_at is set before saving
        entry.published_at ||= Time.current
        
        # Save entry with all extracted data
        entry.save!
      rescue StandardError => e
        puts "Error processing page #{page.url}: #{e.message}".colorize(:red)
        puts e.backtrace.join("\n").colorize(:red)
        puts '--------------------------------------------------------------------"'
        next
      end
    end
  rescue StandardError => e
    puts "Error processing site #{site.name}: #{e.message}".colorize(:red)
    puts e.backtrace.join("\n").colorize(:red)
    puts '--------------------------------------------------------------------"'
    next
  end
end
