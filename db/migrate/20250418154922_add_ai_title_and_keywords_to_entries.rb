# frozen_string_literal: true
class AddAiTitleAndKeywordsToEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :entries, :ai_title, :text
    add_column :entries, :ai_description, :text
    add_column :entries, :keywords, :text
    add_column :entries, :entities, :text
  end
end
