require "test_helper"

# Fast (non-browser) coverage for the floating sound on/off toggle (see
# games/_sound_toggle.html.erb, javascript/controllers/sound_toggle_controller.js).
# It's meaningless anywhere except an actual game screen, so it must render
# on games#show (host or guest, any status) and nowhere else. The actual
# mute/unmute behavior (localStorage persistence, suppressing playback) is
# client-side and covered by test/system/sound_toggle_test.rb instead.
class SoundToggleRequestTest < ActionDispatch::IntegrationTest
  test "renders on the waiting game screen for the host" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_sound_toggle_present
  end

  test "renders on the waiting game screen for a guest" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    get game_path(code: game.code)

    assert_sound_toggle_present
  end

  test "renders on the active game screen" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_sound_toggle_present
  end

  test "renders on the finished game screen" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :finished, finished_at: Time.current)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_sound_toggle_present
  end

  test "does not render on the home page" do
    get root_path
    assert_response :success

    assert_select "[data-controller=?]", "sound-toggle", count: 0
  end

  test "does not render on the enter page" do
    get enter_path
    assert_response :success

    assert_select "[data-controller=?]", "sound-toggle", count: 0
  end

  private

  def assert_sound_toggle_present
    assert_response :success

    assert_select "button[data-controller=?]", "sound-toggle" do |buttons|
      button = buttons.first
      assert_equal "false", button["aria-pressed"]
      assert_equal I18n.t("games.show.sound.mute_label"), button["aria-label"]
    end
    assert_select "button[data-action=?]", "click->sound-toggle#toggle"
  end
end
