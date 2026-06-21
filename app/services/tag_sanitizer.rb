# frozen_string_literal: true

class TagSanitizer < ApplicationService
  MAX_DISPLAY_TAGS = 12
  MIN_TAG_LENGTH = 3

  BLOCKED_TAGS = [
    'america',
    'beast',
    'driver',
    'english',
    'eshop',
    'e-shop',
    'e shop',
    'europe',
    'extreme',
    'fox',
    'game',
    'games',
    'hidden',
    'hunter',
    'japan',
    'legendary',
    'maze',
    'nintendo',
    'nintendo eshop',
    'nintendo switch',
    'nintendo switch 2',
    'nintendo switch 2 edition',
    'nintendo switch 2 eshop',
    'north america',
    'off',
    'one',
    'pc',
    'queen',
    'rogue',
    'run',
    'switch',
    'switch 2',
    'switch 2 edition',
    'switch 2 eshop',
    'us',
    'usa',
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
