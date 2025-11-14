# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :topics
  accepts_nested_attributes_for :topics

  has_many :taggings, dependent: :destroy
  validates :name, presence: true, uniqueness: true

  after_create :schedule_tag_entries_job
  after_update :schedule_tag_entries_job, if: :saved_change_to_name?

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
    Topic.joins(:tags).where(tags: { id: id }).exists?
  end

  private

  def schedule_tag_entries_job
    Tags::TagEntriesJob.perform_later(id, 1.month.ago..Time.current)
  end
end
