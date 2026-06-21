# frozen_string_literal: true

class Genre < ApplicationRecord
  serialize :raw_data, coder: JSON

  has_many :game_genres, dependent: :destroy
  has_many :games, through: :game_genres

  validates :rawg_id, :name, :slug, presence: true
  validates :rawg_id, :slug, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def to_param
    slug
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at games_count id id_value image_background name rawg_id slug updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[game_genres games]
  end
end
