# frozen_string_literal: true

class Game < ApplicationRecord
  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres

  serialize :platforms, coder: JSON
  serialize :rawg_genres, coder: JSON
  serialize :stores, coder: JSON
  serialize :raw_data, coder: JSON

  validates :rawg_id, :name, :slug, presence: true
  validates :rawg_id, :slug, uniqueness: true

  scope :released, -> { where.not(released: nil) }
  scope :recent, -> { order(released: :desc, name: :asc) }

  def to_param
    slug
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[background_image created_at id id_value metacritic name playtime rating rating_top ratings_count rawg_id
       rawg_updated_at released slug tba updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[game_genres genres]
  end
end
