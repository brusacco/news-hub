# frozen_string_literal: true

class Game < ApplicationRecord
  acts_as_taggable_on :name_tags

  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres
  has_many :entry_games, dependent: :destroy
  has_many :entries, through: :entry_games
  has_many :screenshots, -> { ordered }, dependent: :destroy, inverse_of: :game

  serialize :platforms, coder: JSON
  serialize :rawg_genres, coder: JSON
  serialize :stores, coder: JSON
  serialize :metacritic_platforms, coder: JSON
  serialize :ratings, coder: JSON
  serialize :reactions, coder: JSON
  serialize :added_by_status, coder: JSON
  serialize :alternative_names, coder: JSON
  serialize :esrb_rating, coder: JSON
  serialize :raw_data, coder: JSON

  validates :rawg_id, :name, :slug, presence: true
  validates :rawg_id, :slug, uniqueness: true

  scope :released, -> { where.not(released: nil) }
  scope :recent, -> { order(released: :desc, name: :asc) }

  def self.default_name_tag_for(name)
    name.to_s
        .delete_suffix(' - Nintendo Switch')
        .delete_suffix(' Nintendo Switch')
        .delete_suffix(' Switch')
        .squish
  end

  def to_param
    slug
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[achievements_count added additions_count background_image background_image_additional created_at creators_count
       description game_series_count id id_value metacritic metacritic_url movies_count name name_original
       parent_achievements_count parents_count playtime rating rating_top ratings_count rawg_id rawg_updated_at
       reddit_count reddit_logo reddit_name reddit_url released reviews_text_count screenshots_count slug
       suggestions_count tba twitch_count updated_at website youtube_count]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[entries entry_games game_genres genres name_tags screenshots]
  end
end
