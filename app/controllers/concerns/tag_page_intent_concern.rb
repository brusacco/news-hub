# frozen_string_literal: true

module TagPageIntentConcern
  extend ActiveSupport::Concern

  private

  def load_matching_entities_for_tag(tag)
    @matching_developer = matching_developer(tag)
    @matching_genre = matching_genre(tag)
  end

  def matching_developer(tag)
    Developer.find_by('LOWER(name) = ?', tag.name.downcase)
  end

  def matching_genre(tag)
    Genre.find_by('LOWER(name) = ?', tag.name.downcase)
  end
end
