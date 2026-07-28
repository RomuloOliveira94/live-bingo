require "test_helper"

class GameChannelTest < ActionCable::Channel::TestCase
  test "anyone with valid code subscribes" do
    game = games(:one)
    stub_connection(session: nil)

    subscribe code: game.code

    assert subscription.confirmed?
    assert_has_stream_for game
  end

  test "host of game subscribes" do
    game = games(:one)
    stub_connection(session: SessionData.new(host_id: game.host_session_id))

    subscribe code: game.code

    assert subscription.confirmed?
    assert_has_stream_for game
  end

  test "viewer subscribes" do
    game = games(:one)
    stub_connection(session: SessionData.new(host_id: "other_host"))

    subscribe code: game.code

    assert subscription.confirmed?
    assert_has_stream_for game
  end

  test "invalid game code is rejected" do
    stub_connection(session: nil)

    subscribe code: "INVALID"

    assert subscription.rejected?
  end

  test "viewer_count increments on subscribe" do
    game = games(:one)
    assert_equal 0, game.viewer_count

    stub_connection(session: nil)
    subscribe code: game.code

    game.reload
    assert_equal 1, game.viewer_count
  end

  test "viewer_count decrements on unsubscribe" do
    game = games(:one)
    game.update!(viewer_count: 2)

    stub_connection(session: nil)
    subscribe code: game.code

    # After subscribe, viewer_count is 3 (2 + 1)
    game.reload
    assert_equal 3, game.viewer_count

    unsubscribe

    game.reload
    assert_equal 2, game.viewer_count
  end
end
