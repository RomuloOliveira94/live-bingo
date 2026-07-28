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

  # XX/T1 are Cloudflare's own "no real country" sentinels (see RequestGeo) —
  # RequestGeo already resolves them to a blank country_code, so from
  # LocaleResolver's point of view this is identical to no CF-IPCountry
  # header at all: no country signal, Accept-Language isn't Portuguese, so
  # it falls all the way through to the default locale (Rule 4).
  test "XX (unresolved country) with an English Accept-Language defaults to pt-BR (no real country signal)" do
    request = FakeRequest.new({ "CF-IPCountry" => "XX", "Accept-Language" => "en-US,en;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "T1 (Tor) with an English Accept-Language defaults to pt-BR (no real country signal)" do
    request = FakeRequest.new({ "CF-IPCountry" => "T1", "Accept-Language" => "en-US,en;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "T1 (Tor) with a Portuguese Accept-Language resolves to pt-BR" do
    request = FakeRequest.new({ "CF-IPCountry" => "T1", "Accept-Language" => "pt-BR,pt;q=0.9,en;q=0.8" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  # This is the bug from the Part A report, reproduced at the unit level: a
  # Brazilian developer running `bin/dev` locally has no CF-IPCountry header
  # at all (no Cloudflare in front of localhost), and their browser/OS
  # happens to be set to English. There is no country signal here to fall
  # back to (Rule 4), so this must land on the default locale, not on
  # whatever Accept-Language says — otherwise every non-Portuguese browser
  # locale renders English for every visitor of a non-Cloudflare deployment,
  # Brazilian or not.
  test "no Cloudflare header at all (local dev) with an English Accept-Language defaults to pt-BR" do
    request = FakeRequest.new({ "Accept-Language" => "en-US,en;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "no usable signal anywhere defaults to pt-BR" do
    request = FakeRequest.new({})
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "an Accept-Language we don't map, with no country, falls back to the default locale" do
    request = FakeRequest.new({ "Accept-Language" => "es-ES,es;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  # Accept-Language is an explicit statement of the visitor's own
  # preference; CF-IPCountry is only a proxy inference from the request's
  # IP. A Lusophone visitor outside Brazil (Portugal, Angola, Mozambique...)
  # sending `Accept-Language: pt` must not be overridden by a non-BR
  # country lookup. Also covers the Portugal case from QA's repro table
  # (CF-IPCountry: PT + Accept-Language: pt-PT -> pt-BR).
  test "Accept-Language pt wins over a non-Brazil country" do
    request = FakeRequest.new({ "CF-IPCountry" => "PT", "Accept-Language" => "pt-PT,pt;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)

    request = FakeRequest.new({ "CF-IPCountry" => "US", "Accept-Language" => "pt,en;q=0.8" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  # This is the Part A bug itself: a Brazilian user (CF-IPCountry: BR) whose
  # browser/OS is set to English must still see pt-BR — the whole point of
  # the fix is that Accept-Language no longer short-circuits ahead of a
  # Brazilian country match for English (or any other non-Portuguese
  # language). This test used to assert :en, consecrating the bug; it now
  # asserts the required behavior.
  test "Brazil resolves to pt-BR even when Accept-Language says English" do
    request = FakeRequest.new({ "CF-IPCountry" => "BR", "Accept-Language" => "en-US,en;q=0.9" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "no Accept-Language, Brazil country still resolves to pt-BR" do
    request = FakeRequest.new({ "CF-IPCountry" => "BR" })
    assert_equal :"pt-BR", LocaleResolver.call(request)
  end

  test "no Accept-Language, US country still resolves to en" do
    request = FakeRequest.new({ "CF-IPCountry" => "US" })
    assert_equal :en, LocaleResolver.call(request)
  end
end
