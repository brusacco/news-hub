# frozen_string_literal: true

require 'test_helper'

class GenresControllerTest < ActionDispatch::IntegrationTest
  test 'routes genres index' do
    assert_routing '/genres', controller: 'genres', action: 'index'
  end

  test 'routes genres show' do
    assert_routing '/genres/action', controller: 'genres', action: 'show', id: 'action'
  end
end
