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

    assert_equal "Live Bingo!", result
  end

  test "missing key in both locales raises now that raise_on_missing_translations is on" do
    # Was: I18n.t silently returned a "translation missing" string, so a
    # typo'd key never failed a test. config/environments/test.rb now sets
    # raise_on_missing_translations, so this — and any real typo'd key
    # exercised by the suite — raises instead.
    assert_raises(I18n::MissingTranslationData) do
      I18n.t("nonexistent.key", locale: :"pt-BR")
    end
  end
end
