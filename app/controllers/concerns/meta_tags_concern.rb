# frozen_string_literal: true

module MetaTagsConcern
  extend ActiveSupport::Concern

  TITLE_MAX_LENGTH = 60
  DESCRIPTION_MAX_LENGTH = 160

  private

  def set_default_meta_tags(options = {})
    defaults = {
      site_name: 'NintendoNewsHub.com',
      og: {
        site_name: 'NintendoNewsHub.com',
        locale: 'en_US'
      },
      twitter: {
        site: '@NintendoNewsHub'
      }
    }
    set_meta_tags defaults.deep_merge(options)
  end

  def optimized_title(text)
    return text if text.blank?
    text.length > TITLE_MAX_LENGTH ? "#{text[0..(TITLE_MAX_LENGTH - 4)]}..." : text
  end

  def optimized_description(text, fallback: nil)
    text = text.presence || fallback || 'Read the latest Nintendo news and updates on Nintendo News Hub.'
    text.length > DESCRIPTION_MAX_LENGTH ? "#{text[0..(DESCRIPTION_MAX_LENGTH - 4)]}..." : text
  end

  def default_image_url
    root_url + 'apple-touch-icon.png'
  end
end

