# frozen_string_literal: true

class CreateSites < ActiveRecord::Migration[7.1]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
