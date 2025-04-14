# frozen_string_literal: true

class Topic < ApplicationRecord
  has_and_belongs_to_many :tags
  accepts_nested_attributes_for :tags

  before_update :remove_words_spaces

  scope :active, -> { where(status: true) }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id id_value name updated_at]
  end
end
