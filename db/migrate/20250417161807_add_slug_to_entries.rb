# frozen_string_literal: true

class AddSlugToEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :entries, :slug, :string
    add_index :entries, :slug, unique: true
  end
end
