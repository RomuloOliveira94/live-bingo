require "test_helper"

class ClientIpTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers, :remote_ip)

  test "prefers CF-Connecting-IP when Cloudflare set it" do
    request = FakeRequest.new({ "CF-Connecting-IP" => "203.0.113.5" }, "10.0.0.2")
    assert_equal "203.0.113.5", ClientIp.call(request)
  end

  test "falls back to remote_ip when there is no Cloudflare header (local dev / not behind Cloudflare)" do
    request = FakeRequest.new({}, "198.51.100.7")
    assert_equal "198.51.100.7", ClientIp.call(request)
  end

  test "falls back to remote_ip when the Cloudflare header is present but blank" do
    request = FakeRequest.new({ "CF-Connecting-IP" => "" }, "198.51.100.7")
    assert_equal "198.51.100.7", ClientIp.call(request)
  end
end
