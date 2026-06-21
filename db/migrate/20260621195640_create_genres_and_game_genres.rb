# frozen_string_literal: true

class CreateGenresAndGameGenres < ActiveRecord::Migration[7.1]
  def change
    create_table :genres do |t|
      t.integer :rawg_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :games_count
      t.string :image_background
      t.text :raw_data

      t.timestamps
    end

    add_index :genres, :rawg_id, unique: true
    add_index :genres, :slug, unique: true

    create_table :game_genres do |t|
      t.references :game, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end

    add_index :game_genres, %i[game_id genre_id], unique: true
  end
end
