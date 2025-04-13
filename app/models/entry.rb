# frozen_string_literal: true

class Entry < ApplicationRecord
  belongs_to :site

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true

  # Add any additional logic or associations as needed
end
