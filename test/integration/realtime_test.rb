require "test_helper"
require "turbo/broadcastable/test_helper"

# Covers the realtime broadcasting contract for start/finish/restart/draw —
# not just the HTTP response, but what actually goes out over the game's
# Turbo Stream, since that's what a connected guest's browser reacts to.
#
# Background: start/finish used to broadcast_replace_to targets
# ("game-status", "last-ball") that don't even exist on every branch of
# show.html.erb, so a guest on the wrong branch never updated. The fix is a
# full morphed page refresh for start/restart, and a dedicated
# notice+redirect broadcast for finish (see test/system/game_lifecycle_broadcast_test.rb
# for the end-to-end, two-browser version of this).
class RealtimeTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  test "draw broadcasts the ball, history, drawn count, and board" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    streams = nil
    assert_difference "Draw.count", 1 do
      streams = capture_turbo_stream_broadcasts(game) { post draw_game_path(code: game.code) }
    end
    assert_response :redirect

    targets = streams.map { |stream| stream["target"] }
    assert_equal %w[last-ball draw-history drawn-count board].sort, targets.sort
  end

  test "restart clears draws and broadcasts a full page refresh" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    game.draws.create!(number: 1, position: 1)
    sign_in_as_host(game)

    streams = nil
    assert_difference "Draw.count", -1 do
      streams = capture_turbo_stream_broadcasts(game) { post restart_game_path(code: game.code) }
    end
    assert_response :redirect
    assert_includes streams.map { |stream| stream["action"] }, "refresh"
  end

  test "game start broadcasts a full page refresh so guests flip out of the waiting branch" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    streams = capture_turbo_stream_broadcasts(game) { post start_game_path(code: game.code) }
    assert_response :redirect

    game.reload
    assert_equal "active", game.status
    assert_includes streams.map { |stream| stream["action"] }, "refresh"
  end

  test "game finish redirects everyone home with a notice instead of a targeted fragment update" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_host(game)

    streams = capture_turbo_stream_broadcasts(game) { post finish_game_path(code: game.code) }
    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("games.show.finished.message"), flash[:notice]

    game.reload
    assert_equal "finished", game.status

    actions_by_target = streams.each_with_object({}) { |stream, memo| memo[stream["target"]] = stream["action"] }
    assert_equal "replace", actions_by_target["flash"]
    assert_equal "append", actions_by_target["redirect-slot"]
  end
end
