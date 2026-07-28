require "test_helper"

class SessionDataTest < ActiveSupport::TestCase
  test "round-trip through cookies" do
    data = SessionData.new(host_id: "abc123")
    cookie_jar = {}
    data.write_to(cookie_jar)

    assert cookie_jar.key?(:bingo_session)
    parsed = JSON.parse(cookie_jar[:bingo_session])
    assert_equal "abc123", parsed["host_id"]
  end

  test "host_id_for_new_game generates 32-char hex" do
    host_id = SessionData.host_id_for_new_game
    assert_equal 32, host_id.length
    assert_match(/\A[a-f0-9]{32}\z/, host_id)
  end

  test "write_new creates and writes cookie" do
    cookie_jar = {}
    data = SessionData.write_new(cookie_jar)

    assert data.host_id.present?
    assert cookie_jar.key?(:bingo_session)
  end

  test "host_of? returns true for matching host" do
    game = games(:one)
    data = SessionData.new(host_id: game.host_session_id)
    assert data.host_of?(game)
  end

  test "host_of? returns false for non-matching host" do
    game = games(:one)
    data = SessionData.new(host_id: "other_host_id")
    refute data.host_of?(game)
  end

  test "host_of? returns false for blank host_id" do
    game = games(:one)
    data = SessionData.new(host_id: nil)
    refute data.host_of?(game)
  end

  test "cookies_to_session returns nil for blank cookie" do
    assert_nil SessionData.cookies_to_session({})
  end

  test "cookies_to_session handles invalid JSON" do
    cookies = { bingo_session: "not-json" }
    assert_nil SessionData.cookies_to_session(cookies)
  end
end
