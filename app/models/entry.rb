# frozen_string_literal: true

class Entry < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  acts_as_taggable_on :tags
  belongs_to :site

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true

  scope :a_week_ago, -> { where(published_at: 1.week.ago..Time.current) }
  scope :a_day_ago, -> { where(published_at: 1.day.ago..Time.current) }
  scope :no_image, -> { where(image_url: nil) }
  scope :no_published_at, -> { where(published_at: nil) }
  scope :needs_ai_generation, -> { where.not(content: nil).where(ai_content: nil).order(published_at: :desc) }
  scope :tagger_scope, -> { where(published_at: 4.years.ago..Time.current).order(published_at: :desc) }

  def self.ransackable_associations(_auth_object = nil)
    ['site']
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ai_content ai_summary author category content created_at id id_value image_url
       published_at site_id source_name source_url summary title updated_at]
  end

  def prompt
    "Act as a seasoned journalist and subject matter expert in Nintendo news and game development.
    Write a search-optimized article suitable for publication on a professional gaming news website.
    The article should follow SEO best practices and maintain a tone that is informative, authoritative,
    and tailored for an audience familiar with the gaming industry.
    Begin with a strong, SEO-optimized title that includes a relevant keyphrase related to the main topic.
    Start the article with an introductory paragraph that provides background context on the subject,
    including relevant information about the game, developer, or hardware involved. In the body, include a rewritten
    version of any notable quotes or statements using clear, journalistic language.
    Enrich the article with only verified, factual information such as release dates, sales milestones,
    platform history, or developer achievements—do not include speculation or fabricated content.
    Ensure the total word count is at least 300–500 words to support SEO goals, and naturally incorporate keywords
    such as the game title, developer name, and hardware platform (e.g., Nintendo Switch, Nintendo Direct, eShop, etc.).
    The final article should be well-structured, easy to scan, and optimized for both readers and search engines.
    Return the article in a JSON structure like this,
    {ai_title: 'Your Title Here',
    ai_description: 'Short description for meta tags',
    keywords: 'Comma-separated Rich SEO keywords for this article',
    entities:'Comma-separated Extract importante entities from the content, like company names, developers, games',
    ai_content: 'Your article content here'}.
    Do not include any additional text or commentary outside of the JSON structure and remove any trailing spaces
    from the keywords and entities JSON fields content(remove the space after the commnas).
    Always check the JSON structure for errors and ensure it is valid.

    The text to rewrite is:
    #{content}
    "
  end

  def final_title
    ai_title || title
  end

  def final_description
    ai_description || description
  end

  def final_keywords
    keywords || 'Nintendo, News, Aggregator, Switch, Wii U'
  end
end
