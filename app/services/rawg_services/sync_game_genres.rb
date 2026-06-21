# frozen_string_literal: true

module RawgServices
  class SyncGameGenres < ApplicationService
    DEFAULT_BATCH_SIZE = 500

    def self.sync_game!(game, genres_data = game.rawg_genres)
      game.genres = Array(genres_data).filter_map { |genre_data| upsert_genre(genre_data) }
    end

    def self.upsert_genre(genre_data)
      rawg_id = genre_data['id']
      slug = genre_data['slug']

      return if rawg_id.blank? || slug.blank?

      Genre.find_or_initialize_by(rawg_id: rawg_id).tap do |genre|
        genre.assign_attributes(attributes_for(genre, genre_data))
        genre.save!
      end
    end

    def self.attributes_for(genre, genre_data)
      attributes = {
        name: genre_data['name'],
        slug: genre_data['slug']
      }

      attributes[:games_count] = genre_data['games_count'] if genre_data['games_count'].present?
      attributes[:image_background] = genre_data['image_background'] if genre_data['image_background'].present?

      attributes[:raw_data] = genre_data if update_raw_data?(genre, genre_data)

      attributes
    end

    def self.update_raw_data?(genre, genre_data)
      genre.raw_data.blank? || genre_data['games_count'].present? || genre_data['image_background'].present?
    end

    def initialize(scope: Game.where.not(rawg_genres: nil), batch_size: DEFAULT_BATCH_SIZE)
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
