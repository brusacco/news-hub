# frozen_string_literal: true

namespace :rawg do
  desc 'Import Nintendo Switch games from RAWG. Set RAWG_API_KEY, PAGES, PAGE_SIZE, and ORDERING.'
  task import_games: :environment do
    result = RawgServices::ImportNintendoSwitchGames.call(
      api_key: ENV.fetch('RAWG_API_KEY', nil),
      pages: ENV.fetch('PAGES', 1),
      page_size: ENV.fetch('PAGE_SIZE', RawgServices::ImportNintendoSwitchGames::DEFAULT_PAGE_SIZE),
      ordering: ENV.fetch('ORDERING', '-released')
    )

    abort "RAWG import failed: #{result.error}" unless result.success?

    puts "Imported #{result.data} Nintendo Switch games from RAWG"
  end
end
