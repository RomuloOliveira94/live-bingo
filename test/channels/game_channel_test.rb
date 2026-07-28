require "test_helper"
require "turbo/broadcastable/test_helper"

class GameChannelTest < ActionCable::Channel::TestCase
  include Turbo::Broadcastable::TestHelper

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

  # Regression: this broadcast used to render games/_viewer_count.html.erb
  # (translated label included) inside this Action Cable worker thread,
  # which has no per-request locale — see LocaleResolver /
  # ApplicationController#set_locale — so it always rendered at
  # config.i18n.default_locale (pt-BR), no matter what locale any given
  # subscriber's own page was in. Forcing I18n.locale to :en here simulates
  # whatever locale happened to be left over on this thread; the broadcast
  # must carry no translated text either way — just the number.
  test "viewer_count broadcast carries only the raw number, never rendered/translated text" do
    game = games(:one)
    stub_connection(session: nil)

    streams = I18n.with_locale(:en) { capture_turbo_stream_broadcasts(game) { subscribe code: game.code } }

    assert_equal 1, streams.length
    stream = streams.first
    assert_equal "update", stream["action"]
    assert_equal "viewer-count-value", stream["target"]
    assert_equal "1", stream.at("template").text.strip
  end
end
