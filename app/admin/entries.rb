# frozen_string_literal: true

ActiveAdmin.register Entry do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :title, :summary, :content, :ai_summary, :ai_content, :source_url, :source_name, :published_at, :author, :image_url, :category, :site_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:title, :summary, :content, :ai_summary, :ai_content, :source_url, :source_name, :published_at, :author, :image_url, :category, :site_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
end
