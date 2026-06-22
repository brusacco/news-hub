# frozen_string_literal: true

require 'test_helper'

class DevelopersControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'www.nintendonewshub.com'
    @site = Site.create!(name: 'Nintendo News Hub', url: 'https://example.com')
  end

  test 'routes developers index' do
    assert_routing '/developers', controller: 'developers', action: 'index'
  end

  test 'routes developers show' do
    assert_routing '/developers/cd-projekt-red', controller: 'developers', action: 'show', id: 'cd-projekt-red'
  end

  test 'developer show includes related news for linked games' do
    developer = Developer.create!(rawg_id: 9023, name: 'CD PROJEKT RED', slug: 'cd-projekt-red')
    game = Game.create!(rawg_id: 12_345, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    game.developers << developer

    entry = Entry.create!(
      site: @site,
      title: 'Cyberpunk 2077 arrives on Nintendo platforms',
      description: 'Cyberpunk 2077 description',
      source_url: 'https://example.com/cyberpunk-news-dev',
      published_at: 1.hour.ago
    )
    EntryGame.create!(entry:, game:, match_source: 'title_tag', confidence: 100)

    controller = DevelopersController.new
    related_entries = controller.send(:related_entries, developer)

    assert_equal [entry], related_entries.to_a
  end
end
