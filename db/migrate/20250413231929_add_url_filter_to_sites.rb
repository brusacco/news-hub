# frozen_string_literal: true

class AddUrlFilterToSites < ActiveRecord::Migration[7.1]
  def change
    add_column :sites, :url_filter, :string
  end
end
