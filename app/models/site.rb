# frozen_string_literal: true

class Site < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :name, :url, presence: true
  validates :url, uniqueness: true

  # Add any additional logic or associations as needed
end
