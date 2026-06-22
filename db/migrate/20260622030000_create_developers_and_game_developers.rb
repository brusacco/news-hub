# frozen_string_literal: true

class CreateDevelopersAndGameDevelopers < ActiveRecord::Migration[7.1]
  def change
    add_game_developer_columns
    create_developers_table
    create_game_developers_table
  end

  private

  def add_game_developer_columns
    add_column :games, :rawg_developers, :text
    add_column :games, :primary_developer_name, :string
    add_column :games, :developers_count, :integer, default: 0, null: false
  end

  def create_developers_table
    create_table :developers do |t|
      t.integer :rawg_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :games_count
      t.string :image_background
      t.text :raw_data

      t.timestamps
    end

    add_index :developers, :rawg_id, unique: true
    add_index :developers, :slug, unique: true
  end

  def create_game_developers_table
    create_table :game_developers do |t|
      t.references :game, null: false, foreign_key: true
      t.references :developer, null: false, foreign_key: true

      t.timestamps
    end

    add_index :game_developers, %i[game_id developer_id], unique: true
  end
end
