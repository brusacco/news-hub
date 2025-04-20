# frozen_string_literal: true

set :environment, 'production'

every 5.minutes do
  rake 'update_ai'
end

every :hour do
  rake 'crawler'
  rake 'tagger'
  rake 'update_stats'
  rake 'update_content'
  rake 'update_entries'
  rake 'sitemap:refresh:no_ping'
end
