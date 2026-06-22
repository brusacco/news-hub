# frozen_string_literal: true

module EntryMetaTagsConcern
  extend ActiveSupport::Concern

  private

  def set_entry_meta_tags
    title = entry_seo_title
    description = entry_seo_description
    tag_names = normalized_tag_names
    keywords = entry_keywords(tag_names)
    image_url = entry_meta_image_url

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: keywords,
      canonical: entry_url(@entry),
      og: open_graph_meta(title, description, image_url, tag_names),
      article: article_meta(tag_names),
      twitter: twitter_meta(title, description, image_url)
    )
  end

  def entry_seo_title
    branded_title = "#{@entry.final_title} | Nintendo News Hub"
    return branded_title if branded_title.length <= MetaTagsConcern::TITLE_MAX_LENGTH

    optimized_title(@entry.final_title)
  end

  def entry_seo_description
    base_description = @entry.final_description.presence || @entry.description.to_s
    games_text = @games.first(2).map(&:name).to_sentence
    tags_text = @entry.display_title_tags(limit: 2).map(&:name).to_sentence

    optimized_description(entry_description_text(base_description, games_text, tags_text))
  end

  def entry_description_suffix(games_text, tags_text)
    parts = ['Get the key Nintendo details, release context, and related coverage']
    parts << "for #{games_text}" if games_text.present?
    parts << "including #{tags_text}" if tags_text.present?

    "#{parts.to_sentence} on Nintendo News Hub."
  end

  def normalized_tag_names
    @entry.display_tags(limit: nil).map { |tag| TagSanitizer.normalize(tag.name) }
  end

  def entry_keywords(tag_names)
    (base_keywords + expanded_tag_keywords(tag_names) + category_keywords + default_keywords).uniq.join(', ')
  end

  def entry_meta_image_url
    @entry.image_url.presence || default_image_url
  end

  def open_graph_meta(title, description, image_url, tag_names)
    {
      title: title,
      description: description,
      type: 'article',
      url: entry_url(@entry),
      image: image_url,
      published_time: @entry.published_at&.iso8601,
      author: 'Nintendo News Hub',
      section: @entry.category || 'Gaming News',
      tag: tag_names.join(', ')
    }
  end

  def article_meta(tag_names)
    {
      published_time: @entry.published_at&.iso8601,
      author: 'Nintendo News Hub',
      section: @entry.category || 'Gaming News',
      tag: tag_names.join(', '),
      expiration_time: nil,
      modified_time: @entry.updated_at&.iso8601
    }
  end

  def twitter_meta(title, description, image_url)
    {
      card: 'summary_large_image',
      title: title,
      description: description,
      image: image_url,
      creator: '@NintendoNewsHub',
      site: '@NintendoNewsHub'
    }
  end

  def entry_description_text(base_description, games_text, tags_text)
    text = if base_description.present?
             sanitized_description_text(base_description)
           else
             "Read the latest Nintendo news about #{@entry.final_title}."
           end

    "#{text} #{entry_description_suffix(games_text, tags_text)}"
  end

  def sanitized_description_text(text)
    ActionController::Base.helpers.strip_tags(text).squish
  end

  def base_keywords
    @entry.final_keywords.present? ? @entry.final_keywords.split(',').map(&:strip) : []
  end

  def expanded_tag_keywords(tag_names)
    tag_names.flat_map do |tag|
      [tag, "#{tag} news", "Nintendo #{tag}"]
    end
  end

  def category_keywords
    @entry.category.present? ? [@entry.category, "#{@entry.category} news"] : []
  end

  def default_keywords = ['Nintendo news', 'gaming news', 'Nintendo Switch', 'Nintendo updates']
end
