# frozen_string_literal: true

class Site < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :name, :url, presence: true
  validates :url, uniqueness: true

  def self.ransackable_associations(auth_object = nil)
    ["entries"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["active", "created_at", "id", "id_value", "name", "updated_at", "url"]
  end
end
