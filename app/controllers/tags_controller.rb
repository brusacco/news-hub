# frozen_string_literal: true

class TagsController < ApplicationController
  include Pagy::Backend
  include MetaTagsConcern

  def index
    @pagy, @tags = pagy(Tag.popular, limit: 100)

    # SEO-optimized with keyword-rich content
    set_default_meta_tags(
      title: 'Nintendo Topics & Categories - Browse All Gaming News Topics',
      description: 'Browse all Nintendo news topics, categories, and keywords. ' \
                   "Explore #{@tags.count}+ gaming topics including franchises, characters, games, and hardware. " \
                   'Find the latest Nintendo news organized by topic on Nintendo News Hub.',
      keywords: 'Nintendo topics, Nintendo categories, Nintendo tags, gaming topics, ' \
                'Nintendo keywords, Nintendo news categories, gaming news topics, ' \
                'Nintendo Switch topics, Nintendo game categories',
      canonical: tags_url,
      og: {
        title: 'Nintendo Topics & Categories - Browse All Gaming News Topics',
        description: "Browse all Nintendo news topics and categories. Explore #{@tags.count}+ gaming topics including franchises, characters, games, and hardware.",
        url: tags_url
      },
      twitter: {
        card: 'summary',
        title: 'Nintendo Topics & Categories - Browse All Gaming News Topics',
        description: "Browse all Nintendo news topics and categories. Explore #{@tags.count}+ gaming topics."
      }
    )
  end

  def show
    @tag = Tag.friendly.find(params[:id])
    @entries = Entry.tagged_with(@tag.name).includes(:tags, :site).recent
    @pagy, @entries = pagy(@entries, limit: 60)

    # SEO-optimized title with keyword at the beginning
    title = optimized_title("#{@tag.name} News - Latest Updates & Articles | Nintendo News Hub")

    # Rich description with keyword variations and context
    article_count = @tag.taggings_count || 0
    article_text = if article_count > 0
                     "#{ActionController::Base.helpers.number_with_delimiter(article_count)} "
                   else
                     ''
                   end
    description = optimized_description(
      "Stay updated with the latest #{@tag.name} news, updates, and articles. " \
      "Discover #{article_text}articles about #{@tag.name} on Nintendo News Hub. " \
      "Your trusted source for #{@tag.name} gaming news, releases, and insights."
    )

    # Expanded keywords with semantic variations
    keywords = [
      @tag.name,
      "#{@tag.name} news",
      "#{@tag.name} updates",
      "#{@tag.name} articles",
      "Nintendo #{@tag.name}",
      "#{@tag.name} Nintendo",
      "latest #{@tag.name}",
      "#{@tag.name} gaming news"
    ].join(', ')

    set_default_meta_tags(
      title: title,
      description: description,
      keywords: keywords,
      canonical: tag_url(@tag),
      og: {
        title: title,
        description: description,
        type: 'website',
        url: tag_url(@tag)
      },
      twitter: {
        card: 'summary_large_image',
        title: title,
        description: description
      }
    )
  end
end
