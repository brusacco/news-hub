# frozen_string_literal: true

class Screenshot < ApplicationRecord
  belongs_to :game, inverse_of: :screenshots

  serialize :raw_data, coder: JSON

  validates :rawg_id, :image, presence: true
  validates :rawg_id, uniqueness: { scope: :game_id }

  scope :ordered, -> { order(:position, :id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at game_id height id id_value image is_deleted position raw_data rawg_id updated_at width]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[game]
  end
end
