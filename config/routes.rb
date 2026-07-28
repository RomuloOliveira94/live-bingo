Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/manifest" => "rails/pwa#manifest", defaults: { format: :json }
  get "/service-worker" => "rails/pwa#service_worker", defaults: { format: :js }

  # Crawler-facing endpoints (see SeoController). Only "/" and "/entrar" are
  # public, indexable pages — game show pages are ephemeral, private-by-code
  # URLs and are deliberately excluded here (see SeoController#sitemap) and
  # disallowed entirely in robots.txt (see SeoController#robots), on top of
  # each game page's own noindex meta tag.
  get "/robots.txt" => "seo#robots", defaults: { format: :text }
  get "/sitemap.xml" => "seo#sitemap", defaults: { format: :xml }

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
