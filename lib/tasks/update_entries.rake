# frozen_string_literal: true

desc 'Re-process entries with no images'
task update_entries: :environment do
  require 'httparty'
  require 'nokogiri'

  Entry.no_published_at.find_each do |entry|
    response = HTTParty.get(entry.source_url)
    if response.code == 200
      page = Nokogiri::HTML(response.body)
      #---------------------------------------------------------------------------
      # Basic data extractor
      #---------------------------------------------------------------------------
      result = WebExtractorServices::ExtractBasicInfo.call(page)
      if result.success?
        entry.update!(result.data)
      else
        puts "ERROR BASIC: #{result.error}"
      end

      #---------------------------------------------------------------------------
      # Date extractor
      #---------------------------------------------------------------------------
      result = WebExtractorServices::ExtractDate.call(page)
      if result.success?
        entry.update!(result.data)
        puts result.data
      else
        puts "ERROR DATE: #{result&.error}"
      end

      puts "Successfully processed entry with ID: #{entry.id}"
    else
      puts "Failed to fetch URL for entry with ID: #{entry.id}, HTTP Code: #{response.code}"
    end
  rescue StandardError => e
    puts "Error processing entry with ID: #{entry.id}, Error: #{e.message}"
  end
end
