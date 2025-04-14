class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @entries = Entry.all.order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end
end
