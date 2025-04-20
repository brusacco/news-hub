class AddFbPostedToEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :entries, :fb_posted, :boolean, default: false, null: false
  end
end
