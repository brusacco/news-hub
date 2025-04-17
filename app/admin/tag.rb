# frozen_string_literal: true

ActiveAdmin.register Tag do
  permit_params :name, :slug, :variations, topic_ids: []

  #------------------------------------------------------------------
  #
  #------------------------------------------------------------------
  action_item :retag_entries, only: %i[edit show] do
    link_to 'Retag entries', retag_entries_admin_tag_path(tag.id), method: :put, data: { confirm: 'Are you sure?' }
  end

  #------------------------------------------------------------------
  #
  #------------------------------------------------------------------
  member_action :retag_entries, method: :put do
    Tags::UpdateTagEntriesJob.perform_later(params[:id])
    redirect_to admin_tags_path, notice: 'Running tag updates'
  end

  filter :name
  filter :variations

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  #------------------------------------------------------------------
  #
  #------------------------------------------------------------------
  index do
    selectable_column
    id_column
    column :name
    column :variations
    column :created_at
    column :taggings_count
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :variations
    end
    f.actions
  end
end
