Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "games#new"

  resources :games, only: [ :new, :create, :show ], param: :code do
    member do
      post :start
      post :finish
    end
    resources :cards, only: [ :create ]
    resources :draws, only: [ :create ]
    resources :wins, only: [ :update ]
  end
end
