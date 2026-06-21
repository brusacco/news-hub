# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # rubocop:disable Rails/HasAndBelongsToMany
  has_and_belongs_to_many :topics
  # rubocop:enable Rails/HasAndBelongsToMany
  accepts_nested_attributes_for :topics

  has_many :taggings, dependent: :destroy
  validates :name, presence: true, uniqueness: true

  attr_accessor :interactions

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value name taggings_count updated_at variations]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[taggings topics]
  end

  scope :popular, -> { order(taggings_count: :desc) }
  scope :matching_name, ->(query) { where('LOWER(name) LIKE ?', "%#{query.downcase}%") }

  def belongs_to_any_topic?
    Topic.joins(:tags).exists?(tags: { id: id })
  end
end
