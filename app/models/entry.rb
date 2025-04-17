# frozen_string_literal: true

class Entry < ApplicationRecord
  acts_as_taggable_on :tags
  belongs_to :site

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true

  scope :a_week_ago, -> { where(published_at: 1.week.ago..Time.current) }
  scope :no_image, -> { where(image_url: nil) }
  scope :no_published_at, -> { where(published_at: nil) }

  def self.ransackable_associations(_auth_object = nil)
    ['site']
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ai_content ai_summary author category content created_at id id_value image_url
       published_at site_id source_name source_url summary title updated_at]
  end
end
