# frozen_string_literal: true

ActiveAdmin.register Entry do
  permit_params :title, :summary, :content, :ai_summary, :ai_content, :source_url, :source_name, :published_at,
                :author, :image_url, :category, :site_id

  filter :title
  filter :source_url
  filter :published_at

  index do
    selectable_column
    column :id
    column :title
    column :tags
    column :published_at
    actions
  end
end
