# frozen_string_literal: true

class CreateEntryGames < ActiveRecord::Migration[7.1]
  def change
    create_table :entry_games do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.string :match_source, null: false
      t.integer :confidence, null: false, default: 0
      t.string :matched_text
      t.timestamps
    end

    add_index :entry_games, %i[entry_id game_id], unique: true
    add_index :entry_games, :confidence
    add_index :entry_games, :match_source
  end
end
