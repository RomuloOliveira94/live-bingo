require "test_helper"

# Fast (non-browser) coverage mirroring test/system/navbar_test.rb: the
# navbar's right-hand side is context-dependent (see
# ApplicationHelper#navbar_variant) — home keeps both create/join CTAs, the
# enter page drops "Entrar", and every game screen swaps them for the game's
# own code + copy + share, regardless of whether the viewer is the host or a
# guest.
class NavbarRequestTest < ActionDispatch::IntegrationTest
  test "home navbar shows both create and enter CTAs" do
    get root_path
    assert_response :success

    assert_select "header" do
      assert_select "form[action=?]", games_path do
        assert_select "button", text: I18n.t("nav.cta.create")
      end
      assert_select "a[href=?]", enter_path, text: I18n.t("nav.cta.enter")
      assert_select "[data-controller=clipboard]", count: 0
    end
  end

  test "enter page navbar shows only the create CTA" do
    get enter_path
    assert_response :success

    assert_select "header" do
      assert_select "form[action=?]", games_path do
        assert_select "button", text: I18n.t("nav.cta.create")
      end
      assert_select "a[href=?]", enter_path, count: 0
    end
  end

  test "waiting game navbar shows the game code, copy, and share (host)" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_navbar_shows_game(game)
  end

  test "waiting game navbar shows the game code, copy, and share (guest)" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    get game_path(code: game.code)

    assert_navbar_shows_game(game)
  end

  test "active game navbar shows the game code, copy, and share" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_navbar_shows_game(game)
  end

  test "finished game navbar shows the game code, copy, and share" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :finished, finished_at: Time.current)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_navbar_shows_game(game)
  end

  private

  def assert_navbar_shows_game(game)
    assert_response :success

    assert_select "header" do
      assert_select "[data-controller=clipboard][data-clipboard-text-value=?]", game.code
      assert_select "[data-controller=share]"
      assert_select "form[action=?]", games_path, count: 0
      assert_select "a[href=?]", enter_path, count: 0
    end
    assert_select "header", text: /#{Regexp.escape(game.code[0, 3])}/
  end
end
