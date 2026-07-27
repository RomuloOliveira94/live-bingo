require "test_helper"

class SessionDataTest < ActiveSupport::TestCase
  test "round-trip through cookies" do
    data = SessionData.new(role: "host", game_id: 42, host_session_id: "abc123")

    # Mock cookies object
    cookie_jar = {}

    data.write_to(cookie_jar)

    # Verify cookie was set
    assert cookie_jar.key?(:bingo_session)
    cookie_data = cookie_jar[:bingo_session]

    # In test mode, it's just the JSON value
    parsed = JSON.parse(cookie_data)
    assert_equal "host", parsed["role"]
    assert_equal 42, parsed["game_id"]
    assert_equal "abc123", parsed["host_session_id"]
  end

  test "host_for factory" do
    game = games(:one)
    data = SessionData.host_for(game)

    assert_equal "host", data.role
    assert_equal game.id, data.game_id
    assert_equal game.host_session_id, data.host_session_id
    assert_nil data.guest_session_id
  end

  test "guest_for factory" do
    game = games(:one)
    data = SessionData.guest_for(game, session_id: "guest_abc")

    assert_equal "guest", data.role
    assert_equal game.id, data.game_id
    assert_nil data.host_session_id
    assert_equal "guest_abc", data.guest_session_id
  end

  test "to_h returns hash with compact" do
    data = SessionData.new(role: "host", game_id: 1, host_session_id: "abc")
    hash = data.to_h

    assert_equal({ role: "host", game_id: 1, host_session_id: "abc" }, hash)
  end

  test "to_h excludes nil values" do
    data = SessionData.new(role: "guest", game_id: 1, guest_session_id: "xyz")
    hash = data.to_h

    assert_equal({ role: "guest", game_id: 1, guest_session_id: "xyz" }, hash)
    refute hash.key?(:host_session_id)
  end
end
