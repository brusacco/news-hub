# frozen_string_literal: true

class RenameGamesGenresToRawgGenres < ActiveRecord::Migration[7.1]
  def change
    rename_column :games, :genres, :rawg_genres
  end
end
