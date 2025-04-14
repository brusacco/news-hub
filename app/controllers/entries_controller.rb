class EntriesController < ApplicationController
  def index
  end

  def show
    @entry = Entry.find(params[:id])
    @entries = Entry.where.not(id: @entry.id).order(published_at: :desc).limit(8)
  end
end
