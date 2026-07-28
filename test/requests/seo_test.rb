require "test_helper"

# Coverage for Part C's SEO/social pass: per-page <title>/description, Open
# Graph, Twitter Card, canonical/hreflang, the JSON-LD structured data, and
# the crawler-facing robots.txt/sitemap.xml endpoints. See SeoHelper,
# layouts/_seo_head.html.erb, and SeoController.
class SeoTest < ActionDispatch::IntegrationTest
  test "home renders full SEO head in pt-BR" do
    get root_path, headers: { "CF-IPCountry" => "BR" }
    assert_response :success

    expected_title = "#{I18n.t('app.tagline', locale: :"pt-BR")} · #{I18n.t('app.name')}"
    expected_description = I18n.t("seo.description", locale: :"pt-BR")

    assert_select "title", text: expected_title
    assert_select "meta[name=description][content=?]", expected_description
    assert_select "meta[name=robots][content=?]", "index, follow"

    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_select "link[rel=alternate][hreflang=?][href=?]", "pt-BR", "http://www.example.com/"
    assert_select "link[rel=alternate][hreflang=?][href=?]", "en", "http://www.example.com/"
    assert_select "link[rel=alternate][hreflang=?][href=?]", "x-default", "http://www.example.com/"

    assert_select "meta[property='og:type'][content=?]", "website"
    assert_select "meta[property='og:site_name'][content=?]", I18n.t("app.name")
    assert_select "meta[property='og:title'][content=?]", expected_title
    assert_select "meta[property='og:description'][content=?]", expected_description
    assert_select "meta[property='og:url'][content=?]", "http://www.example.com/"
    assert_select "meta[property='og:image'][content=?]", "http://www.example.com/og-image.png"
    assert_select "meta[property='og:image:width'][content=?]", "1200"
    assert_select "meta[property='og:image:height'][content=?]", "630"
    assert_select "meta[property='og:locale'][content=?]", "pt_BR"
    assert_select "meta[property='og:locale:alternate'][content=?]", "en_US"

    assert_select "meta[name='twitter:card'][content=?]", "summary_large_image"
    assert_select "meta[name='twitter:title'][content=?]", expected_title
    assert_select "meta[name='twitter:description'][content=?]", expected_description
    assert_select "meta[name='twitter:image'][content=?]", "http://www.example.com/og-image.png"

    assert_valid_structured_data(
      description: expected_description,
      url: "http://www.example.com/"
    )
  end

  test "home renders full SEO head in en, with locale/alternate flipped" do
    get root_path, headers: { "CF-IPCountry" => "US" }
    assert_response :success

    expected_title = "#{I18n.t('app.tagline', locale: :en)} · #{I18n.t('app.name')}"
    expected_description = I18n.t("seo.description", locale: :en)

    assert_select "title", text: expected_title
    assert_select "meta[name=description][content=?]", expected_description
    assert_select "meta[property='og:locale'][content=?]", "en_US"
    assert_select "meta[property='og:locale:alternate'][content=?]", "pt_BR"
  end

  test "enter page has its own distinct title, description, and canonical" do
    get enter_path
    assert_response :success

    expected_title = "#{I18n.t('pages.enter.title', locale: :"pt-BR")} · #{I18n.t('app.name')}"
    expected_description = I18n.t("seo.enter_description", locale: :"pt-BR")

    assert_select "title", text: expected_title
    assert_select "meta[name=description][content=?]", expected_description
    assert_select "meta[name=robots][content=?]", "index, follow"
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/entrar"
    assert_select "meta[property='og:url'][content=?]", "http://www.example.com/entrar"
  end

  test "a game show page is noindex, has its own description, and a code-specific canonical" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    get game_path(code: game.code)
    assert_response :success

    expected_description = I18n.t("seo.game_description", locale: :"pt-BR")

    assert_select "title", text: "#{I18n.t('games.show.title', locale: :"pt-BR")} · #{I18n.t('app.name')}"
    assert_select "meta[name=description][content=?]", expected_description
    # This is the privacy-sensitive bit: game codes must never be indexed.
    assert_select "meta[name=robots][content=?]", "noindex, nofollow"
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/games/#{game.code}"
  end

  test "structured data validates as WebApplication with a free (price 0) offer" do
    get root_path

    assert_valid_structured_data(
      description: I18n.t("seo.description", locale: :"pt-BR"),
      url: "http://www.example.com/"
    )
  end

  test "robots.txt disallows game pages and points at the sitemap" do
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type

    assert_match(/^Disallow: \/games\/$/, response.body)
    assert_match(%r{^Sitemap: http://www\.example\.com/sitemap\.xml$}, response.body)
  end

  test "sitemap.xml lists only the public pages, never a game" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type

    assert_includes response.body, "<loc>http://www.example.com/</loc>"
    assert_includes response.body, "<loc>http://www.example.com/entrar</loc>"
    assert_not_includes response.body, "games"
    assert_not_includes response.body, game.code
  end

  private

  def assert_valid_structured_data(description:, url:)
    json_ld = Nokogiri::HTML::Document.parse(response.body).at_css('script[type="application/ld+json"]')
    assert json_ld, "expected a <script type=\"application/ld+json\"> tag in the response"

    data = JSON.parse(json_ld.text)

    assert_equal "https://schema.org", data["@context"]
    assert_equal "WebApplication", data["@type"]
    assert_equal I18n.t("app.name"), data["name"]
    assert_equal description, data["description"]
    assert_equal url, data["url"]
    assert_equal "0", data.dig("offers", "price")
    assert_equal "Offer", data.dig("offers", "@type")
  end
end
