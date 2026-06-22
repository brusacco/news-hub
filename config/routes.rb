# frozen_string_literal: true

Rails.application.routes.draw do
  resources :entries, path: 'news', only: %i[index show]
  resources :games, only: %i[index show]
  resources :genres, only: %i[index show]
  resources :developers, only: %i[index show]
  resources :tags, only: %i[index show]

  get 'home/index'
  get 'search', to: 'home#search', as: :search
  get 'search/autocomplete', to: 'home#search_autocomplete', as: :search_autocomplete
  get 'trending' => 'home#trending', as: :trending
  get '/who-we-are', to: 'home#who', as: :who
  get '/terms-of-service', to: 'home#terms', as: :terms
  get '/privacy-policy', to: 'home#privacy', as: :privacy

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'home#index'
end
