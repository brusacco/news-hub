# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[7.1]
  # rubocop:disable Metrics/AbcSize
  def change
    create_table :games do |t|
      t.integer :rawg_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.date :released
      t.boolean :tba, default: false, null: false
      t.string :background_image
      t.decimal :rating, precision: 4, scale: 2
      t.integer :rating_top
      t.integer :ratings_count
      t.integer :metacritic
      t.integer :playtime
      t.datetime :rawg_updated_at
      t.text :platforms
      t.text :genres
      t.text :stores
      t.text :raw_data

      t.timestamps
    end

    add_index :games, :rawg_id, unique: true
    add_index :games, :slug, unique: true
    add_index :games, :released
  end
  # rubocop:enable Metrics/AbcSize
end
