# frozen_string_literal: true

class Game < ApplicationRecord
  serialize :platforms, coder: JSON
  serialize :genres, coder: JSON
  serialize :stores, coder: JSON
  serialize :raw_data, coder: JSON

  validates :rawg_id, :name, :slug, presence: true
  validates :rawg_id, :slug, uniqueness: true

  scope :released, -> { where.not(released: nil) }
  scope :recent, -> { order(released: :desc, name: :asc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[background_image created_at id id_value metacritic name playtime rating rating_top ratings_count rawg_id
       rawg_updated_at released slug tba updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
