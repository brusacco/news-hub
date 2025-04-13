# frozen_string_literal: true

class AddSiteToEntries < ActiveRecord::Migration[7.1]
  def change
    add_reference :entries, :site, null: false, foreign_key: true
  end
end
