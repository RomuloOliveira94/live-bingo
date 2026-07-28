require "test_helper"

class AnonymizedIpTest < ActiveSupport::TestCase
  test "zeroes the last octet of an IPv4 address" do
    assert_equal "189.45.32.0", AnonymizedIp.call("189.45.32.77")
  end

  test "truncates an IPv6 address to its /64 network prefix" do
    assert_equal "2001:db8:85a3::", AnonymizedIp.call("2001:db8:85a3:0:1111:2222:3333:4444")
  end

  test "returns nil for a blank input instead of raising" do
    assert_nil AnonymizedIp.call(nil)
    assert_nil AnonymizedIp.call("")
  end

  test "returns nil for an unparseable input instead of raising" do
    assert_nil AnonymizedIp.call("not-an-ip")
  end
end
