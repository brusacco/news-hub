# frozen_string_literal: true

require 'koala'

desc 'Post to Game new Hub fanpage'
task fanpage_poster: :environment do
  token = 'EAAUflRsiNdYBAKVFkQO2p8ywoQ6O1BZBfTG5ZB3W7JizMO3gyZBbKInG9sZCzCn01p5gZByWtleV7iE8GoP7uqdqpGvi21ZADJ0cZAaV0WIr5dbqG4ZAZCRIlSiHxuyAg3Iqif2GaBvpjRNgs3ZAwSI6Aa6MPqsKHCXmOreIdgRvpitwZDZD'
  user_graph = Koala::Facebook::API.new(token)
  page_token = user_graph.get_page_access_token('61575674214440')
  page_graph = Koala::Facebook::API.new(page_token)
  page_graph.get_object('me') # I'm a page
  page_graph.get_connection('me', 'feed') # the page's wall
  page_id = '61575674214440'

  Entry.where.not(ai_title: nil).limit(100).each do |entry|
    begin
      page_graph.put_connections(page_id, 'feed', message: ai_title, link: entry_path(entry))
      entry.posted = true
      entry.save
    rescue StandardError => e
      puts e.message
      next
    end
    sleep(rand(60..150))
  end
end
