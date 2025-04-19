# frozen_string_literal: true

desc 'Tagger'
task tagger: :environment do
  Entry.tagger_scope.find_each do |entry|
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

task retagger: :environment do
  Entry.find_each do |entry|
    next if entry.entities.blank?

    entry.tag_list.add(entry.entities, parse: true)
    puts entry.source_url
    puts entry.tag_list
    puts '---------------------------------------------------'

    entry.save
  rescue StandardError => e
    puts "Error: #{e.message}"
    sleep 1
    retry
  end
end
