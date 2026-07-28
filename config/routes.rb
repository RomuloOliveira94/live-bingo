Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/manifest" => "rails/pwa#manifest", defaults: { format: :json }
  get "/service-worker" => "rails/pwa#service_worker", defaults: { format: :js }

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
