# frozen_string_literal: true

class AddRawgDetailFieldsToGames < ActiveRecord::Migration[7.1]
  def change
    change_table :games, bulk: true do |t|
      t.string :name_original
      t.text :description
      t.text :metacritic_platforms
      t.string :background_image_additional
      t.string :website
      t.text :ratings
      t.text :reactions
      t.integer :added
      t.text :added_by_status
      t.integer :screenshots_count
      t.integer :movies_count
      t.integer :creators_count
      t.integer :achievements_count
      t.string :parent_achievements_count
      t.string :reddit_url
      t.string :reddit_name
      t.text :reddit_description
      t.string :reddit_logo
      t.integer :reddit_count
      t.string :twitch_count
      t.string :youtube_count
      t.string :reviews_text_count
      t.integer :suggestions_count
      t.text :alternative_names
      t.string :metacritic_url
      t.integer :parents_count
      t.integer :additions_count
      t.integer :game_series_count
      t.text :esrb_rating
    end
  end
end
