# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class TagSanitizer < ApplicationService
  MAX_DISPLAY_TAGS = 12
  MIN_TAG_LENGTH = 3

  BLOCKED_TAGS = [
    'ages',
    'america',
    'amiibo',
    'beast',
    'coin',
    'collect',
    'console',
    'control',
    'cursor',
    'driver',
    'egg',
    'english',
    'e-shop',
    'e shop',
    'eshop',
    'europe',
    'extreme',
    'feel',
    'fox',
    'franchise',
    'galaxy 2',
    'game',
    'gamestop',
    'games',
    'happy',
    'hidden',
    'hunter',
    'ice',
    'japan',
    'joy',
    'joy-cons',
    'kid',
    'kondo',
    'legendary',
    'luma',
    'lumas',
    'mario franchise',
    'mario galaxy',
    'mario galaxy 2',
    'mario series',
    'maze',
    'miyamoto',
    'mother',
    'mushroom',
    'nintendo',
    'nintendo ead',
    'nintendo eshop',
    'nintendo switch',
    'nintendo switch 2',
    'nintendo switch 2 edition',
    'nintendo switch 2 eshop',
    'north america',
    'off',
    'one',
    'pc',
    'pro controller',
    'queen',
    'ray',
    'red',
    'rogue',
    'run',
    'soundtrack',
    'storybook',
    'sunshine',
    'switch',
    'switch 2',
    'switch 2 edition',
    'switch 2 eshop',
    'switch port',
    'time',
    'tokyo',
    'us',
    'usa',
    'wii',
    'wii u',
    'vs'
  ].freeze

  SPECIAL_CASES = {
    'capcom' => 'Capcom',
    'eggconsole' => 'EGGCONSOLE',
    'namco' => 'Namco',
    'pc-9801' => 'PC-9801'
  }.freeze

  def initialize(tags, limit: nil)
    @tags = Array(tags)
    @limit = limit
  end

  def call
    tags = normalized_tags
    @limit ? tags.first(@limit) : tags
  end

  def self.allowed?(tag)
    new([tag]).call.any?
  end

  def self.normalize(tag)
    new([tag]).call.first
  end

  private

  def normalized_tags
    @tags.each_with_object([]) do |tag, sanitized|
      name = sanitized_name(tag)
      next if name.blank?

      sanitized << name unless sanitized.any? { |existing| existing.casecmp?(name) }
    end
  end

  def sanitized_name(tag)
    raw_name = tag.respond_to?(:name) ? tag.name : tag
    name = raw_name.to_s.squish
    return if blocked?(name)

    canonicalize(name)
  end

  def blocked?(name)
    normalized_name = name.downcase

    normalized_name.length < MIN_TAG_LENGTH || BLOCKED_TAGS.include?(normalized_name)
  end

  def canonicalize(name)
    SPECIAL_CASES.fetch(name.downcase) { titleize_preserving_punctuation(name) }
  end

  def titleize_preserving_punctuation(name)
    name.downcase.gsub(/[[:alpha:]]+/, &:capitalize)
  end
end
# rubocop:enable Metrics/ClassLength
