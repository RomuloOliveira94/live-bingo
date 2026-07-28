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

  test "cookies_to_session parses visitor_token when present" do
    cookies = { bingo_session: { host_id: "abc123", visitor_token: "tok123" }.to_json }
    data = SessionData.cookies_to_session(cookies)
    assert_equal "tok123", data.visitor_token
  end

  test "cookies_to_session tolerates a pre-existing cookie with no visitor_token" do
    cookies = { bingo_session: { host_id: "abc123" }.to_json }
    data = SessionData.cookies_to_session(cookies)
    assert_nil data.visitor_token
  end

  test "ensure_session mints a visitor_token when there is no cookie at all" do
    cookies = {}
    data = SessionData.ensure_session(cookies)

    assert data.visitor_token.present?
    assert_nil data.host_id
    assert cookies.key?(:bingo_session)
  end

  test "ensure_session preserves an existing host_id while minting a missing visitor_token" do
    cookies = { bingo_session: { host_id: "existing-host" }.to_json }
    data = SessionData.ensure_session(cookies)

    assert_equal "existing-host", data.host_id
    assert data.visitor_token.present?
  end

  test "ensure_session leaves an already-complete cookie untouched" do
    cookies = { bingo_session: { host_id: "h1", visitor_token: "v1" }.to_json }
    data = SessionData.ensure_session(cookies)

    assert_equal "h1", data.host_id
    assert_equal "v1", data.visitor_token
  end

  test "write_new preserves an existing visitor_token across game creation" do
    cookies = { bingo_session: { host_id: nil, visitor_token: "existing-visitor" }.to_json }
    data = SessionData.write_new(cookies)

    assert_equal "existing-visitor", data.visitor_token
    assert data.host_id.present?
  end

  test "write_new mints a visitor_token when there was none yet" do
    cookies = {}
    data = SessionData.write_new(cookies)

    assert data.visitor_token.present?
  end
end
