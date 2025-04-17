# frozen_string_literal: true

class EntriesController < ApplicationController
  def index; end

  def show
    @entry = Entry.friendly.find(params[:id])
    @entries = Entry.tagged_with(@entry.tags, any: true).order(published_at: :desc).limit(9)
    @entries = Entry.where.not(id: @entry.id).order(published_at: :desc).limit(9) unless @entries.any?
  end
end
