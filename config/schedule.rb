# frozen_string_literal: true

set :environment, 'production'

every :hour do
  rake 'crawler'
  rake 'tagger'
  rake 'update_stats'
  rake 'update_content'
  rake 'update_entries'
end
