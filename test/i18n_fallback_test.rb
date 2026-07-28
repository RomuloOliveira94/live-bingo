require "test_helper"

class I18nFallbackTest < ActiveSupport::TestCase
  test "fallback from pt-BR to en works for missing keys" do
    # Inject a translation that only exists in :en (not a real locale-file key,
    # so this doesn't collide with the pt-BR/en key-parity test) and confirm
    # I18n falls back to it when pt-BR is missing the key.
    I18n.backend.store_translations(:en, i18n_fallback_test_only_key: "Only in English")

    result = I18n.t("i18n_fallback_test_only_key", locale: :"pt-BR")

    assert_equal "Only in English", result
  end

  test "pt-BR keys take precedence over en fallback" do
    # The key "app.name" exists in pt-BR.yml
    result = I18n.t("app.name", locale: :"pt-BR")

    assert_equal "Bingo", result
  end

  test "missing key in both locales returns translation missing" do
    result = I18n.t("nonexistent.key", locale: :"pt-BR")

    assert_match(/translation missing/i, result)
  end
end
