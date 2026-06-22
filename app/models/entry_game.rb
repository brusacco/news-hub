# frozen_string_literal: true

class EntryGame < ApplicationRecord
  belongs_to :entry
  belongs_to :game

  validates :match_source, presence: true
  validates :confidence, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :entry_id, uniqueness: { scope: :game_id }

  scope :strongest_first, -> { order(confidence: :desc, updated_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[confidence created_at entry_id game_id id id_value match_source matched_text updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[entry game]
  end
end
