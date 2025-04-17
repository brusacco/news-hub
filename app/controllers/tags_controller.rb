# frozen_string_literal: true

class TagsController < ApplicationController
  include Pagy::Backend
  def index
    @tags = Tag.all
  end

  def show
    @tag = Tag.friendly.find(params[:id])
    @entries = Entry.tagged_with(@tag.name).order(published_at: :desc)
    @pagy, @entries = pagy(@entries, limit: 60)
  end
end
