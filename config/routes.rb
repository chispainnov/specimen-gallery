# config/routes.rb
Rails.application.routes.draw do
  root "specimen_assets#index"
  resources :specimen_assets, only: %i[index show new create]

  namespace :admin do
    resources :specimen_assets, only: %i[index update]
  end
end

