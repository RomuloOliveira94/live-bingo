require "test_helper"

class LocaleResolverTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers)

  test "Brazil resolves to pt-BR" do
    request = FakeRequest.new({ "CF-IPCountry" => "BR" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "a non-Brazil country resolves to en" do
    request = FakeRequest.new({ "CF-IPCountry" => "US" })
    assert_equal :en, LocaleResolver.call(request)

    request = FakeRequest.new({ "CF-IPCountry" => "JP" })
    assert_equal :en, LocaleResolver.call(request)
  end

  test "XX (unresolved country) falls through to the Accept-Language header" do
    request = FakeRequest.new({ "CF-IPCountry" => "XX", "Accept-Language" => "en-US,en;q=0.9" })
    assert_equal :en, LocaleResolver.call(request)
  end

  test "T1 (Tor) falls through to the Accept-Language header" do
    request = FakeRequest.new({ "CF-IPCountry" => "T1", "Accept-Language" => "pt-BR,pt;q=0.9,en;q=0.8" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "no Cloudflare header at all (not behind Cloudflare / local dev) falls through to Accept-Language" do
    request = FakeRequest.new({ "Accept-Language" => "en-GB,en;q=0.9" })
    assert_equal :en, LocaleResolver.call(request)
  end

  test "no usable signal anywhere defaults to pt-BR" do
    request = FakeRequest.new({})
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "an Accept-Language we don't map falls back to the default locale" do
    request = FakeRequest.new({ "Accept-Language" => "es-ES,es;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end
end
