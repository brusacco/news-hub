# frozen_string_literal: true

desc 'Tagger'
task tagger: :environment do
  Entry.order(id: :desc).limit(1000).each do |entry|
    result = WebExtractorServices::ExtractTags.call(entry.id)
    next unless result.success?

    tags = result.data
    tags << entry.entities.split(',') if entry.entities.present?

    entry.tag_list = tags.flatten.uniq
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
