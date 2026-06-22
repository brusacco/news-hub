# frozen_string_literal: true

class CreateScreenshots < ActiveRecord::Migration[7.1]
  def change
    create_table :screenshots do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :rawg_id, null: false
      t.string :image, null: false
      t.integer :width
      t.integer :height
      t.boolean :is_deleted, null: false, default: false
      t.integer :position, null: false, default: 0
      t.text :raw_data

      t.timestamps
    end

    add_index :screenshots, [:game_id, :rawg_id], unique: true
    add_index :screenshots, [:game_id, :position]
  end
end
