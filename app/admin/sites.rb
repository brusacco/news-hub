# frozen_string_literal: true

ActiveAdmin.register Site do
  permit_params :name, :url, :active, :url_filter

  filter :name
end
