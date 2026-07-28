require "test_helper"

class UserAgentParserTest < ActiveSupport::TestCase
  test "Chrome on Windows desktop" do
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Chrome", os: "Windows", device_type: :desktop }, result)
  end

  test "Safari on iPhone is mobile" do
    ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) " \
         "Version/17.5 Mobile/15E148 Safari/604.1"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Safari", os: "iOS", device_type: :mobile }, result)
  end

  test "Firefox on Linux desktop" do
    ua = "Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Firefox", os: "Linux", device_type: :desktop }, result)
  end

  test "Chrome on Android phone is mobile, not tablet" do
    ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Chrome", os: "Android", device_type: :mobile }, result)
  end

  test "Safari on iPad is a tablet" do
    ua = "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/604.1"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Safari", os: "iOS", device_type: :tablet }, result)
  end

  test "Android tablet without the Mobile token is a tablet" do
    ua = "Mozilla/5.0 (Linux; Android 14; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Chrome", os: "Android", device_type: :tablet }, result)
  end

  test "Edge on Windows is recognized as Edge, not Chrome" do
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0"
    result = UserAgentParser.call(ua)

    assert_equal({ browser: "Edge", os: "Windows", device_type: :desktop }, result)
  end

  test "blank user agent yields Other/Other/unknown instead of guessing" do
    assert_equal({ browser: "Other", os: "Other", device_type: :unknown }, UserAgentParser.call(nil))
    assert_equal({ browser: "Other", os: "Other", device_type: :unknown }, UserAgentParser.call(""))
  end
end
