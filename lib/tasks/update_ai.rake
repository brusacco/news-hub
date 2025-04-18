# frozen_string_literal: true

desc 'Update AI content based on the content of the entry'
task update_ai: :environment do
  Parallel.each(Entry.needs_ai_generation.each, in_threads: 5) do |entry|
    prompt = entry.prompt
    result = AiServices::OpenAiQuery.call(prompt)
    next unless result.success?

    entry.update!(result.data)
    puts "Updated AI content for entry ##{entry.id}"
  rescue StandardError => e
    puts "Error processing entry ##{entry.id}: #{e.message}"
  end
end
