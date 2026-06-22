# frozen_string_literal: true

module RawgServices
  class SyncGameDevelopers < ApplicationService
    DEFAULT_BATCH_SIZE = 500

    def self.sync_game!(game, developers_data = extract_developers_data(game))
      developers_data = Array(developers_data)

      game.update!(cache_attributes_for(developers_data))
      game.developers = developers_data.filter_map { |developer_data| upsert_developer(developer_data) }
    end

    def self.extract_developers_data(game)
      game.raw_data.is_a?(Hash) ? game.raw_data['developers'] : nil
    end

    def self.cache_attributes_for(developers_data)
      developers_data = Array(developers_data)

      {
        rawg_developers: developers_data,
        primary_developer_name: developers_data.first&.dig('name'),
        developers_count: developers_data.size
      }
    end

    def self.upsert_developer(developer_data)
      rawg_id = developer_data['id']
      slug = developer_data['slug']

      return if rawg_id.blank? || slug.blank?

      Developer.find_or_initialize_by(rawg_id: rawg_id).tap do |developer|
        developer.assign_attributes(attributes_for(developer_data))
        developer.save!
      end
    end

    def self.attributes_for(developer_data)
      {
        name: developer_data['name'],
        slug: developer_data['slug'],
        games_count: developer_data['games_count'],
        image_background: developer_data['image_background'],
        raw_data: developer_data
      }
    end

    def initialize(scope: Game.where.not(raw_data: [nil, '']), batch_size: DEFAULT_BATCH_SIZE)
      @scope = scope
      @batch_size = batch_size.to_i.positive? ? batch_size.to_i : DEFAULT_BATCH_SIZE
    end

    def call
      synced_count = 0

      @scope.find_each(batch_size: @batch_size) do |game|
        self.class.sync_game!(game)
        synced_count += 1
      end

      handle_success(synced_count)
    rescue StandardError => e
      handle_error(e.message)
    end
  end
end
