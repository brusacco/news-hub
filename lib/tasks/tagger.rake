# frozen_string_literal: true

desc 'Tagger'
task tagger: :environment do
  Entry.where(published_at: 4.years.ago..Time.current).find_each do |entry|
    result = WebExtractorServices::ExtractTags.call(entry.id)
    next unless result.success?

    entry.tag_list = result.data
    puts entry.source_url
    puts entry.tag_list
    puts '---------------------------------------------------'

    entry.save!
    entry.touch
  rescue StandardError => e
    puts e.message
    sleep 1
    retry
  end
end

task retagger: :environment do
  Entry.enabled.where(published_at: 3.months.ago..Time.current).find_each do |entry|
    next if entry.tags.any?

    result = WebExtractorServices::ExtractTags.call(entry.id)
    next unless result.success?

    entry.tag_list = result.data
    puts entry.url
    puts entry.tag_list
    puts '---------------------------------------------------'

    entry.save!
    entry.touch
  rescue StandardError => e
    puts e.message
    sleep 1
    retry
  end
end
