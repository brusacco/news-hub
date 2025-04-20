# frozen_string_literal: true

desc 'Tagger'
task tagger: :environment do
  Entry.order(id: :desc).limit(100).each do |entry|
    result = WebExtractorServices::ExtractTags.call(entry.id)
    next unless result.success?

    entry.tag_list = result.data
    puts entry.source_url
    puts entry.tag_list
    puts '---------------------------------------------------'

    entry.save
  rescue StandardError => e
    puts e.message
    sleep 1
    retry
  end
end
