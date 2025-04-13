# frozen_string_literal: true

class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries do |t|
      t.string   :title
      t.text     :summary
      t.text     :content
      t.text     :ai_summary
      t.text     :ai_content
      t.string   :source_url
      t.string   :source_name
      t.datetime :published_at
      t.string   :author
      t.string   :image_url
      t.string   :category
      t.timestamps
    end

    add_index :entries, :published_at
    add_index :entries, :category
    add_index :entries, :source_url, unique: true
  end
end
