# frozen_string_literal: true

module DeveloperPageContentConcern
  extend ActiveSupport::Concern

  MIN_INDEXABLE_GAMES = 3
  MIN_DESCRIPTION_LENGTH = 220

  private

  def top_genres(developer)
    Genre
      .joins(games: :developers)
      .where(developers: { id: developer.id })
      .distinct
      .order(games_count: :desc, name: :asc)
      .limit(6)
  end

  def indexable_developer_page?(developer, game_count = developer.games.count)
    game_count >= MIN_INDEXABLE_GAMES || rich_description?(developer.description)
  end

  def developer_supporting_copy(developer, featured_games, top_genres)
    return [] unless description_needs_enhancement?(developer.description)

    game_names = featured_games.map(&:name)
    genre_names = top_genres.map(&:name)

    [
      developer_intro_copy(developer.name),
      developer_supporting_copy_details(developer.name, game_names, genre_names)
    ]
  end

  def developer_intro_copy(developer_name)
    "#{developer_name} has a dedicated Nintendo Switch landing page here so players can quickly evaluate " \
      "the studio's most visible releases, genres, and related news coverage in one place."
  end

  def developer_supporting_copy_details(developer_name, game_names, genre_names)
    details = ["Nintendo players visiting this page can use it to explore #{developer_name} games"]
    details << "including #{game_names.to_sentence}" if game_names.any?
    if genre_names.any?
      details << "and browse the genres where the studio appears most often, such as #{genre_names.to_sentence}"
    end

    "#{details.to_sentence}."
  end

  def description_needs_enhancement?(description)
    !rich_description?(description)
  end

  def rich_description?(description)
    ActionController::Base.helpers.strip_tags(description.to_s).squish.length >= MIN_DESCRIPTION_LENGTH
  end
end
