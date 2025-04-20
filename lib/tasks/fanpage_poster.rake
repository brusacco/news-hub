# frozen_string_literal: true

require 'koala'
require 'action_controller'
require 'rails'
include Rails.application.routes.url_helpers
Rails.application.routes.default_url_options[:host] = 'localhost:3000'

desc 'Post to Game new Hub fanpage'
task fanpage_poster: :environment do
  token = 'EAAUflRsiNdYBOxsrHp6OH4k0v3AmXKpi4gJUWVs8vklarUyatBiFZCUtYCxNQsFT085CZCfO8qdhO4M4tJgbjWqopIoe8gvZCxZCrGY10gFBGqCt6EvI3qSOwFQ0seDiaR5NZAZAh6t48PlZCr9wA8Ft0onoWtigSwA1OrQ3xkWhSciWbaKnpcSFzZBigZAkIMgZDZD'
  user_graph = Koala::Facebook::API.new(token)
  page_token = user_graph.get_page_access_token('661560777030650')
  page_graph = Koala::Facebook::API.new(page_token)
  page_graph.get_object('me') # I'm a page
  page_graph.get_connection('me', 'feed') # the page's wall
  page_id = '61575674214440'

  Entry.where.not(ai_title: nil).limit(100).each do |entry|
    begin
      page_graph.put_connections(page_id, 'feed', message: entry.ai_title, link: entry_path(entry))
      entry.posted = true
      entry.save
    rescue StandardError => e
      puts e.message
      next
    end
    sleep(rand(60..150))
  end
end
