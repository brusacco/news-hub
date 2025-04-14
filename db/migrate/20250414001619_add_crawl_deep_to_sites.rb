# frozen_string_literal: true

class AddCrawlDeepToSites < ActiveRecord::Migration[7.1]
  def change
    add_column :sites, :crawl_deep, :integer
    change_column_default :sites, :crawl_deep, 1
  end
end
