# frozen_string_literal: true

require 'test_helper'

class ScreenshotTest < ActiveSupport::TestCase
  test 'requires game rawg id and image' do
    screenshot = Screenshot.new

    assert_not screenshot.valid?
    assert_includes screenshot.errors[:game], 'must exist'
    assert_includes screenshot.errors[:rawg_id], "can't be blank"
    assert_includes screenshot.errors[:image], "can't be blank"
  end

  test 'belongs to game and preserves ordering' do
    game = Game.create!(rawg_id: 1, name: 'Cyberpunk 2077', slug: 'cyberpunk-2077')
    later = game.screenshots.create!(rawg_id: 11, image: 'https://cdn.test/2.jpg', position: 2)
    earlier = game.screenshots.create!(rawg_id: 10, image: 'https://cdn.test/1.jpg', position: 1)

    assert_equal [earlier.id, later.id], game.reload.screenshots.pluck(:id)
  end
end
