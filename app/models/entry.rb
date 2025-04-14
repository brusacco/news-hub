# frozen_string_literal: true

class Entry < ApplicationRecord
  acts_as_taggable_on :tags
  belongs_to :site

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true

  def self.ransackable_associations(_auth_object = nil)
    ['site']
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ai_content ai_summary author category content created_at id id_value image_url
       published_at site_id source_name source_url summary title updated_at]
  end
end
