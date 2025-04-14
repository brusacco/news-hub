class HomeController < ApplicationController
  def index
    @entries = Entry.all.order(published_at: :desc).limit(10)
  end
end
