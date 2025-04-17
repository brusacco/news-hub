# frozen_string_literal: true

ActsAsTaggableOn.strict_case_match = true
ActsAsTaggableOn::Tag.class_eval do
  extend FriendlyId
  friendly_id :name, use: :slugged
end
