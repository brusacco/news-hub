# frozen_string_literal: true

module TagsCleanupTask
  module_function

  def cleanup_forbidden_tags
    batch_size = ENV.fetch('BATCH_SIZE', 25).to_i
    batch_size = 25 unless batch_size.positive?
    forbidden_tags = Tag.find_each.reject { |tag| TagSanitizer.allowed?(tag.name) }
    dry_run = ENV.fetch('DRY_RUN', 'true') != 'false'

    puts "Found #{forbidden_tags.count} forbidden tags"
    print_sample(forbidden_tags)

    return puts('Dry run only. Set DRY_RUN=false to delete these tags.') if dry_run

    puts "Deleted #{delete_forbidden_tags(forbidden_tags, batch_size)} forbidden tags"
  end

  def print_sample(tags)
    tags.first(50).each do |tag|
      puts "#{tag.id}: #{tag.name} (#{tag.taggings_count} taggings)"
    end
  end

  def delete_forbidden_tags(tags, batch_size)
    tags.each_slice(batch_size).sum do |tag_batch|
      delete_forbidden_tag_batch(tag_batch.map(&:id))
    rescue ActiveRecord::StatementInvalid => e
      raise unless database_locked?(e)

      puts "Database locked while deleting tags #{tag_batch.map(&:id).join(', ')}; skipping this batch"
      0
    end
  end

  def delete_forbidden_tag_batch(tag_ids)
    ActsAsTaggableOn::Tagging.where(tag_id: tag_ids).delete_all
    Tag.where(id: tag_ids).delete_all
  end

  def database_locked?(error)
    error.message.include?('database is locked')
  end
end

namespace :tags do
  desc 'Delete forbidden tags using TagSanitizer rules. Dry-run by default; set DRY_RUN=false to delete.'
  task cleanup_forbidden: :environment do
    TagsCleanupTask.cleanup_forbidden_tags
  end
end
