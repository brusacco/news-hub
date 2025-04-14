class HomeController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @entries = pagy(Entry.all.order(published_at: :desc))
  end
end
