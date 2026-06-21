# frozen_string_literal: true

namespace :entries do
  desc 'Delete invalid placeholder entries. Dry-run by default; set DRY_RUN=false to delete.'
  task cleanup_placeholders: :environment do
    scope = Entry.where('LOWER(TRIM(title)) = ?', 'none')
    count = scope.count
    dry_run = ENV.fetch('DRY_RUN', 'true') != 'false'

    puts "Found #{count} placeholder entries"

    scope.limit(20).pluck(:id, :title, :source_url).each do |id, title, source_url|
      puts "#{id}: #{title} - #{source_url}"
    end

    if dry_run
      puts 'Dry run only. Set DRY_RUN=false to delete these entries.'
      next
    end

    deleted = scope.destroy_all.count
    puts "Deleted #{deleted} placeholder entries"
  end
end
