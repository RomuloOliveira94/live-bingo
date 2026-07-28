# Per-page SEO/social metadata (see layouts/_seo_head.html.erb). Views
# override the per-page pieces via `content_for(:title, ...)`,
# `content_for(:description, ...)`, and `content_for(:robots, ...)`; anything
# a view doesn't set falls back to a sensible site-wide default here.
module SeoHelper
  # The exact `<title>` text — "<page-specific> · <app name>", or just the
  # app name when a view hasn't set one. Reused verbatim for og:title and
  # twitter:title so a page's browser tab, its Google result, and its
  # WhatsApp/Slack link preview all show the same headline.
  def page_title
    specific = content_for(:title)
    specific.present? ? "#{specific} · #{t('app.name')}" : t("app.name")
  end

  def page_description
    content_for(:description).presence || t("seo.description")
  end

  # "index, follow" unless a view opts into something stricter — currently
  # only games/show.html.erb does, via content_for(:robots, "noindex,
  # nofollow"): game codes are ephemeral, private-by-URL, and must never be
  # indexed. This is the layer that actually keeps a game page out of the
  # index — robots.txt deliberately still allows crawling it (see
  # config/routes.rb's comment) so link-preview crawlers like
  # facebookexternalhit can fetch it and read this very tag; SeoController's
  # sitemap simply never lists one, so it's never proactively suggested for
  # indexing either.
  def page_robots
    content_for(:robots).presence || "index, follow"
  end

  # Absolute, host-aware URL for the current request — used for
  # canonical/og:url/hreflang. Built from request.base_url (reflects
  # whatever host actually served this request, proxies included) rather
  # than config.action_mailer.default_url_options, which is a mailer-only
  # placeholder ("example.com" / "localhost:3000") never meant to describe
  # this app's own host.
  def canonical_url
    "#{request.base_url}#{request.path}"
  end

  def og_image_url
    "#{request.base_url}/og-image.png"
  end

  # Open Graph's own locale format is `pt_BR`/`en_US` (underscore + region),
  # not our `:"pt-BR"`/`:en` I18n locale symbols.
  def og_locale
    I18n.locale == :"pt-BR" ? "pt_BR" : "en_US"
  end

  def og_locale_alternate
    I18n.locale == :"pt-BR" ? "en_US" : "pt_BR"
  end

  # WebApplication structured data (see layouts/_seo_head.html.erb), rendered
  # as JSON-LD on every page. `offers.price: "0"` is what surfaces this
  # app's free-ness directly in Google's understanding of the page (see the
  # Part B/C brief) — schema.org's own vocabulary (@type, applicationCategory,
  # priceCurrency...) is a fixed technical enum, not user-facing copy, so it
  # isn't translated; `name`/`description` are.
  def structured_data
    {
      "@context" => "https://schema.org",
      "@type" => "WebApplication",
      "name" => t("app.name"),
      "description" => t("seo.description"),
      "url" => "#{request.base_url}#{root_path}",
      "applicationCategory" => "GameApplication",
      "operatingSystem" => "Any",
      "inLanguage" => I18n.available_locales.map(&:to_s),
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "BRL"
      }
    }
  end
end
