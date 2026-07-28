require "test_helper"

# Regression coverage for host/guest parity on the waiting screen (see
# games/_waiting.html.erb): a guest who joins before the host starts now
# sees the same room-code panel, copy/share controls, and player counter as
# the host — everything except the controls that mutate game state, which
# stay host-only both in what renders here AND in what the server accepts
# (GamesController#require_host! is untouched by this — see
# test/requests/games_request_test.rb's "non-host cannot ..." tests).
class WaitingScreenRequestTest < ActionDispatch::IntegrationTest
  test "guest on the waiting screen sees the code panel, copy/share controls, and player counter" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    get game_path(code: game.code)
    assert_response :success

    assert_select "#game-code", text: /#{Regexp.escape(game.code[0, 3])}/
    assert_select "[data-controller=clipboard]"
    assert_select "[data-controller=share]"
    assert_select "#viewer-count"
    assert_select "h1", text: I18n.t("games.show.waiting.guest_heading")
  end

  test "guest on the waiting screen sees none of the host-only mutating controls" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    get game_path(code: game.code)
    assert_response :success

    assert_select "form[action=?]", start_game_path(code: game.code), count: 0
    assert_select "form[action=?]", draw_game_path(code: game.code), count: 0
    assert_select "form[action=?]", restart_game_path(code: game.code), count: 0
    assert_select "form[action=?]", finish_game_path(code: game.code), count: 0
  end

  # Regression: GameChannel's viewer_count broadcast only ever pushes the
  # raw number (see GameChannel#broadcast_viewer_count and its comment) —
  # the pluralized label text comes from what each visitor's OWN GET
  # request already rendered, in their OWN resolved locale, right here.
  test "viewer count's pluralized label renders in the visitor's own resolved locale" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    get game_path(code: game.code), headers: { "CF-IPCountry" => "US" }
    assert_response :success

    assert_select "[data-viewer-count-target='labelOne']", text: I18n.t("games.show.waiting.players_label", count: 1, locale: :en)
    assert_select "[data-viewer-count-target='labelOther']", text: I18n.t("games.show.waiting.players_label", count: 2, locale: :en)
  end

  test "host on the waiting screen still sees the start button and eyebrow heading" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    get game_path(code: game.code)
    assert_response :success

    assert_select "form[action=?]", start_game_path(code: game.code)
    assert_select "h1", text: I18n.t("games.show.waiting.heading")
    assert_select "body", text: /#{I18n.t("games.show.waiting.eyebrow")}/
  end
end
