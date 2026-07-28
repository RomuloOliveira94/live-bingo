require "test_helper"

# End-to-end coverage for country -> locale selection (see LocaleResolver
# and ApplicationController#set_locale): confirms the full request cycle
# actually renders the resolved locale (not just that I18n.locale flips
# internally), and that it never leaks onto the next request handled by the
# same test session/thread.
class LocaleRequestTest < ActionDispatch::IntegrationTest
  test "Brazil renders pt-BR" do
    get root_path, headers: { "CF-IPCountry" => "BR" }
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
    assert_select "body", text: /#{Regexp.escape(I18n.t("pages.home.subtitle", locale: :"pt-BR"))}/
  end

  test "a non-Brazil country renders English end-to-end" do
    get root_path, headers: { "CF-IPCountry" => "US" }
    assert_response :success

    assert_select "html[lang=?]", "en"
    assert_select "body", text: /#{Regexp.escape(I18n.t("pages.home.subtitle", locale: :en))}/
  end

  test "no Cloudflare header and no Accept-Language defaults to pt-BR" do
    get root_path
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
  end

  test "XX (unresolved) and T1 (Tor) are treated as no country" do
    get root_path, headers: { "CF-IPCountry" => "XX" }
    assert_select "html[lang=?]", "pt-BR"

    get root_path, headers: { "CF-IPCountry" => "T1" }
    assert_select "html[lang=?]", "pt-BR"
  end

  test "falls back to the Accept-Language header when there is no country signal" do
    get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }
    assert_response :success

    assert_select "html[lang=?]", "en"
  end

  test "locale does not leak onto the next request handled by the same thread" do
    get root_path, headers: { "CF-IPCountry" => "US" }
    assert_select "html[lang=?]", "en"

    get root_path
    assert_select "html[lang=?]", "pt-BR"
  end

  test "the PWA manifest reflects the resolved locale too" do
    get "/manifest.json", headers: { "CF-IPCountry" => "US" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "en", json["lang"]
  end
end
