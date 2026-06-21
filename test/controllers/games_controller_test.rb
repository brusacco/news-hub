# frozen_string_literal: true

require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  test 'routes games index' do
    assert_routing '/games', controller: 'games', action: 'index'
  end
end
