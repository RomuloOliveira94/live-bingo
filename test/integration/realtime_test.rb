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

  test "draw broadcasts an update (not a replace) for each fragment, so every wrapper's id survives for the next draw" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    # The full-page render is the source of truth for where each fragment's
    # id-bearing wrapper lives. A broadcast that can't find a matching id in
    # here has nowhere to land on a connected guest's page.
    get game_path(code: game.code)
    rendered_page = Nokogiri::HTML5.parse(response.body)

    streams = nil
    assert_difference "Draw.count", 1 do
      streams = capture_turbo_stream_broadcasts(game) { post draw_game_path(code: game.code) }
    end
    assert_response :redirect

    targets = streams.map { |stream| stream["target"] }
    assert_equal %w[last-ball draw-history drawn-count board draw-button].sort, targets.sort

    streams.each do |stream|
      target = stream["target"]

      # This is the crux of the regression: `replace` swaps out the
      # id-bearing wrapper itself, so a SECOND draw would have nothing left
      # to target and would be silently dropped by the browser — exactly
      # what left guests frozen on draw #1. `update` replaces only the
      # wrapper's children, keeping the id alive for every future draw.
      assert_equal "update", stream["action"],
        "##{target} must be updated in place, not replaced, or its id is destroyed after the first broadcast"

      assert rendered_page.at_css("##{target}"),
        "##{target} must exist in the full-page render for the broadcast to have anywhere to land"

      # Guard against a partial re-introducing its own id="#{target}" root
      # node: `update` inserts the partial's markup AS A CHILD of the
      # existing wrapper, so a partial that duplicates the id would nest it
      # one level deeper instead of fixing anything.
      assert_nil stream.at_css("##{target}"),
        "the \"#{target}\" partial must not render its own id=\"#{target}\" element — update() nests it as a child of the wrapper that already owns that id"
    end
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
    assert_equal "update", actions_by_target["flash"]
    assert_equal "append", actions_by_target["redirect-slot"]
  end
end
