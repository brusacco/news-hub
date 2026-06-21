# frozen_string_literal: true

require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  test 'routes games index' do
    assert_routing '/games', controller: 'games', action: 'index'
  end

  test 'routes games show' do
    assert_routing '/games/cyberpunk-2077', controller: 'games', action: 'show', id: 'cyberpunk-2077'
  end
end
