Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/manifest" => "rails/pwa#manifest", defaults: { format: :json }
  get "/service-worker" => "rails/pwa#service_worker", defaults: { format: :js }

  # Crawler-facing endpoints (see SeoController). Only "/" and "/entrar" are
  # public, indexable pages — game show pages are ephemeral, private-by-code
  # URLs and are deliberately excluded from the sitemap here (see
  # SeoController#sitemap), on top of each game page's own noindex meta tag.
  #
  # robots.txt deliberately does NOT `Disallow: /games/` (it used to, and
  # that was a bug): a `Disallow` only stops crawling, it doesn't stop
  # *indexing* (Google can still index a disallowed URL from an external
  # link, just without reading its content) — and it stopped
  # facebookexternalhit/WhatsApp/Twitterbot etc. from ever fetching a shared
  # game link at all, breaking link-preview unfurls for this app's primary
  # sharing flow (a host sharing their room link). noindex + the sitemap
  # omission above are the correct, sufficient pair for "crawlable but
  # never indexed."
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
