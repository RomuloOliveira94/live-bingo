Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  resources :games, only: [ :create, :show ], param: :code do
    member do
      post :start
      post :finish
      post :draw
      post :restart
    end
  end

  get  "/entrar", to: "pages#enter", as: :enter
  post "/entrar", to: "pages#join"
end
