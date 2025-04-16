class AddStatsToEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :entries, :reaction_count, :integer, default: 0, null: false
    add_column :entries, :comment_count, :integer, default: 0, null: false
    add_column :entries, :share_count, :integer, default: 0, null: false
    add_column :entries, :comment_plugin_count, :integer, default: 0, null: false
    add_column :entries, :total_count, :integer, default: 0, null: false
  end
end
