# frozen_string_literal: true

class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end

  def trending
    @entries = Entry.a_week_ago.order(total_count: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end
end
