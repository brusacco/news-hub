# frozen_string_literal: true

class AddDetailFieldsToGenresAndDevelopers < ActiveRecord::Migration[7.1]
  def change
    add_column :genres, :description, :text
    add_column :developers, :description, :text
  end
end
