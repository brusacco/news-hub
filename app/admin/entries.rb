# frozen_string_literal: true

ActiveAdmin.register Entry do
  permit_params :title, :summary, :content, :ai_summary, :ai_content, :source_url, :source_name, :published_at, :author, :image_url, :category, :site_id
end
