# frozen_string_literal: true

class Entry < ApplicationRecord
  extend FriendlyId

  DEFAULT_KEYWORDS = 'Nintendo, News, Aggregator, Switch, Wii U'

  friendly_id :title, use: :slugged

  acts_as_taggable_on :tags
  belongs_to :site

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true
  validates :published_at, presence: true
  validate :published_at_not_in_future
  validate :source_url_format, if: -> { source_url.present? }
  validate :image_url_format, if: -> { image_url.present? }

  scope :published_since, ->(time) { where(published_at: time..Time.current) }
  scope :a_week_ago, -> { published_since(1.week.ago) }
  scope :a_day_ago, -> { published_since(1.day.ago) }
  scope :no_image, -> { where(image_url: nil) }
  scope :needs_ai_generation, -> { where.not(content: nil).where(ai_content: nil).order(published_at: :desc) }
  scope :tagger_scope, -> { published_since(4.years.ago).order(published_at: :desc) }
  scope :recent, -> { order(published_at: :desc) }
  scope :with_tags, -> { includes(:tags) }
  scope :with_site, -> { includes(:site) }
  scope :matching_text, lambda { |query|
    sanitized_query = "%#{sanitize_sql_like(query.to_s.downcase)}%"
    where('LOWER(title) LIKE :query OR LOWER(description) LIKE :query', query: sanitized_query)
  }

  def self.popular_tags(limit: 5)
    EntryPopularTagsQuery.call(limit:)
  end

  def self.ransackable_associations(_auth_object = nil)
    ['site']
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ai_content ai_description ai_summary ai_title author category comment_count comment_plugin_count content
       created_at entities fb_posted id id_value image_url keywords published_at reaction_count share_count site_id slug
       source_name source_url summary title total_count updated_at]
  end

  def prompt
    AiServices::EntryPromptBuilder.call(self)
  end

  def final_title
    ai_title.presence || title
  end

  def final_description
    ai_description.presence || description
  end

  def final_keywords
    keywords.presence || DEFAULT_KEYWORDS
  end

  private

  def published_at_not_in_future
    return if published_at.blank?

    errors.add(:published_at, 'cannot be in the future') if published_at > Time.current
  end

  def source_url_format
    validate_url_format(:source_url, source_url)
  end

  def image_url_format
    validate_url_format(:image_url, image_url)
  end

  def validate_url_format(attribute, url)
    return if url.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/)

    errors.add(attribute, 'must be a valid URL')
  end
end
