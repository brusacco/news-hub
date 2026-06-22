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

namespace :rawg do
  desc 'Backfill game developer relations and cached fields from stored RAWG detail payloads.'
  task sync_game_developers: :environment do
    scope = Game.where.not(raw_data: [nil, ''])

    if ENV['GAME_ID'].present?
      scope = scope.where(id: ENV['GAME_ID'])
    elsif ENV['GAME'].present?
      scope = scope.where(slug: ENV['GAME'])
    elsif ENV['START_ID'].present?
      scope = scope.where(id: ENV['START_ID'].to_i..)
    end

    result = RawgServices::SyncGameDevelopers.call(
      scope:,
      batch_size: ENV.fetch('BATCH_SIZE', RawgServices::SyncGameDevelopers::DEFAULT_BATCH_SIZE)
    )

    abort "RAWG game developer sync failed: #{result.error}" unless result.success?

    puts "Synced developer relations for #{result.data} games"
  end
end

namespace :rawg do
  desc 'Import RAWG screenshots for imported games. Set RAWG_API_KEY and optional GAME, GAME_ID, START_ID, BATCH_SIZE.'
  task import_screenshots: :environment do
    scope = Game.all

    if ENV['GAME_ID'].present?
      scope = scope.where(id: ENV['GAME_ID'])
    elsif ENV['GAME'].present?
      scope = scope.where(slug: ENV['GAME'])
    elsif ENV['START_ID'].present?
      scope = scope.where(id: ENV['START_ID'].to_i..)
    end

    result = RawgServices::ImportGameScreenshots.call(
      api_key: ENV.fetch('RAWG_API_KEY', nil),
      scope:,
      batch_size: ENV.fetch('BATCH_SIZE', RawgServices::ImportGameScreenshots::DEFAULT_BATCH_SIZE),
      replace: ENV.fetch('REPLACE', 'true') != 'false'
    )

    abort "RAWG screenshots import failed: #{result.error}" unless result.success?

    puts "Imported #{result.data} screenshots from RAWG"
  end
end

namespace :rawg do
  desc 'Import detailed RAWG payloads for imported games. Set RAWG_API_KEY and optional GAME, GAME_ID, START_ID, ' \
       'BATCH_SIZE.'
  task import_game_details: :environment do
    scope = Game.all

    if ENV['GAME_ID'].present?
      scope = scope.where(id: ENV['GAME_ID'])
    elsif ENV['GAME'].present?
      scope = scope.where(slug: ENV['GAME'])
    elsif ENV['START_ID'].present?
      scope = scope.where(id: ENV['START_ID'].to_i..)
    end

    result = RawgServices::ImportGameDetails.call(
      api_key: ENV.fetch('RAWG_API_KEY', nil),
      scope:,
      batch_size: ENV.fetch('BATCH_SIZE', RawgServices::ImportGameDetails::DEFAULT_BATCH_SIZE)
    )

    abort "RAWG game details import failed: #{result.error}" unless result.success?

    puts "Imported details for #{result.data} games from RAWG"
  end
end
