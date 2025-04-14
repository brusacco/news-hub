# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end
end
