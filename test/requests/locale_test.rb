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

  # This is the Part A bug end-to-end: no CF-IPCountry header at all (local
  # dev, or any deployment not sitting behind Cloudflare) and an English
  # Accept-Language. There's no country signal to fall back to, so this must
  # render pt-BR (Rule 4), not English — otherwise a Brazilian developer
  # running `bin/dev` locally with an English browser/OS sees the whole app
  # in English. This test used to assert "en", consecrating that bug.
  test "no country signal and an English Accept-Language renders pt-BR, not English" do
    get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
  end

  test "Accept-Language pt wins over a non-Brazil country end-to-end" do
    get root_path, headers: { "CF-IPCountry" => "US", "Accept-Language" => "pt,en;q=0.8" }
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
  end

  # This is the exact bug QA reproduced: a Brazilian user (CF-IPCountry: BR)
  # whose browser/OS is set to English. Accept-Language must no longer
  # short-circuit ahead of the Brazil country match — this test used to
  # assert "en", consecrating the bug the user reported.
  test "Brazil country wins over an English Accept-Language end-to-end" do
    get root_path, headers: { "CF-IPCountry" => "BR", "Accept-Language" => "en-US,en;q=0.9" }
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
  end

  # QA's repro table also included a Portugal case: a Lusophone visitor
  # outside Brazil must still get pt-BR (Rule 1 — Portuguese Accept-Language
  # wins over any country, Brazil or not).
  test "Portugal country with a Portuguese Accept-Language renders pt-BR end-to-end" do
    get root_path, headers: { "CF-IPCountry" => "PT", "Accept-Language" => "pt-PT" }
    assert_response :success

    assert_select "html[lang=?]", "pt-BR"
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
