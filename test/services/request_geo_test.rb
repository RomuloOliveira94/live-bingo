require "test_helper"

class RequestGeoTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers)

  test "extracts country, region, and city from Cloudflare headers" do
    request = FakeRequest.new({ "CF-IPCountry" => "BR", "CF-Region" => "SP", "CF-IPCity" => "Sao Paulo" })
    geo = RequestGeo.call(request)

    assert_equal "BR", geo[:country_code]
    assert_equal "SP", geo[:region]
    assert_equal "Sao Paulo", geo[:city]
  end

  test "treats XX (Cloudflare's unknown-country sentinel) as no country" do
    request = FakeRequest.new({ "CF-IPCountry" => "XX" })
    assert_nil RequestGeo.call(request)[:country_code]
  end

  test "treats T1 (Cloudflare's Tor sentinel) as no country" do
    request = FakeRequest.new({ "CF-IPCountry" => "T1" })
    assert_nil RequestGeo.call(request)[:country_code]
  end

  test "degrades to all-nil when no Cloudflare headers are present (not behind Cloudflare)" do
    request = FakeRequest.new({})
    geo = RequestGeo.call(request)

    assert_nil geo[:country_code]
    assert_nil geo[:region]
    assert_nil geo[:city]
  end

  test "region and city are nil when only country is present (Cloudflare free plan)" do
    request = FakeRequest.new({ "CF-IPCountry" => "US" })
    geo = RequestGeo.call(request)

    assert_equal "US", geo[:country_code]
    assert_nil geo[:region]
    assert_nil geo[:city]
  end
end
