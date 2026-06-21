# frozen_string_literal: true

namespace :rawg do
  desc 'Import RAWG genres. Set RAWG_API_KEY, PAGES, and PAGE_SIZE.'
  task import_genres: :environment do
    result = RawgServices::ImportGenres.call(
      api_key: ENV.fetch('RAWG_API_KEY', nil),
      pages: ENV.fetch('PAGES', nil),
      page_size: ENV.fetch('PAGE_SIZE', RawgServices::ImportGenres::DEFAULT_PAGE_SIZE)
    )

    abort "RAWG genres import failed: #{result.error}" unless result.success?

    puts "Imported #{result.data} genres from RAWG"
  end
end

namespace :rawg do
  desc 'Import Nintendo Switch games from RAWG. Set RAWG_API_KEY, PAGES, PAGE_SIZE, and ORDERING.'
  task import_games: :environment do
    result = RawgServices::ImportNintendoSwitchGames.call(
      api_key: ENV.fetch('RAWG_API_KEY', nil),
      pages: ENV.fetch('PAGES', nil),
      page_size: ENV.fetch('PAGE_SIZE', RawgServices::ImportNintendoSwitchGames::DEFAULT_PAGE_SIZE),
      ordering: ENV.fetch('ORDERING', '-released')
    )

    abort "RAWG import failed: #{result.error}" unless result.success?

    puts "Imported #{result.data} Nintendo Switch games from RAWG"
  end
end

namespace :rawg do
  desc 'Backfill game genre relations from the stored RAWG genre payload.'
  task sync_game_genres: :environment do
    result = RawgServices::SyncGameGenres.call(
      batch_size: ENV.fetch('BATCH_SIZE', RawgServices::SyncGameGenres::DEFAULT_BATCH_SIZE)
    )

    abort "RAWG game genre sync failed: #{result.error}" unless result.success?

    puts "Synced genre relations for #{result.data} games"
  end
end
