require "test_helper"

class I18nFallbackTest < ActiveSupport::TestCase
  test "fallback from pt-BR to en works for missing keys" do
    # The key "hello" exists in en.yml but not in pt-BR.yml
    # With fallback configured, it should return the English value
    result = I18n.t("hello", locale: :"pt-BR")

    assert_equal "Hello world", result
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
