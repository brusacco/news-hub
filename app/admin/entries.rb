# frozen_string_literal: true

ActiveAdmin.register Entry do
  permit_params :title, :summary, :content, :ai_summary, :ai_content, :source_url, :source_name, :published_at,
                :author, :image_url, :category, :site_id, :slug

  filter :title
  filter :source_url
  filter :published_at

  scope :all, default: true
  scope :a_week_ago
  scope :no_image

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  index do
    selectable_column
    column :id
    column :source_url
    column :tags
    column :published_at
    actions
  end
end
