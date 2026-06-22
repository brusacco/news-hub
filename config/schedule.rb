# frozen_string_literal: true

set :environment, 'production'

every 5.minutes do
  rake 'update_ai'
end

every :hour do
  rake 'crawler'
  rake 'tagger'
  rake 'tagger:title_tags'
  rake 'tagger:untagged'
  rake 'games:link_entries'
  rake 'update_stats'
  rake 'update_content'
  rake 'update_entries'
end

every 1.day, at: '5:00 am' do
  rake 'sitemap:refresh:no_ping'
end
