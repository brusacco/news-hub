# frozen_string_literal: true

desc 'Fetch and update content for entries'
task update_content: :environment do
  require 'httparty'

  Entry.limit(10).each do |entry|
    response = HTTParty.get(entry.source_url)
    if response.success?
      html = response.body
      result = WebExtractorServices::ArticleExtractor.call(entry.source_url, html)

      if result.success?
        entry.update(result.data)
        puts "Updated entry ##{entry.id}"
      else
        puts "Failed to extract content for entry ##{entry.id}"
      end
    else
      puts "Failed to fetch URL for entry ##{entry.id}: HTTP #{response.code}"
    end
  rescue StandardError => e
    puts "Error processing entry ##{entry.id}: #{e.message}"
  end
end
