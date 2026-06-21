# frozen_string_literal: true

namespace :tags do
  desc 'Delete forbidden tags using TagSanitizer rules. Dry-run by default; set DRY_RUN=false to delete.'
  task cleanup_forbidden: :environment do
    forbidden_tags = Tag.find_each.reject { |tag| TagSanitizer.allowed?(tag.name) }
    dry_run = ENV.fetch('DRY_RUN', 'true') != 'false'

    puts "Found #{forbidden_tags.count} forbidden tags"

    forbidden_tags.first(50).each do |tag|
      puts "#{tag.id}: #{tag.name} (#{tag.taggings_count} taggings)"
    end

    if dry_run
      puts 'Dry run only. Set DRY_RUN=false to delete these tags.'
      next
    end

    deleted = forbidden_tags.sum do |tag|
      tag.destroy!
      1
    end

    puts "Deleted #{deleted} forbidden tags"
  end
end
