require "test_helper"

# Regression coverage for the sticky-footer page shell (see
# layouts/application.html.erb): <body> is a full-height (dvh, not vh —
# vh ignores a mobile browser's collapsing URL bar and cuts off the
# footer) flex column, the navbar and footer are fixed-size items
# (shrink-0), and <main> is the one growing region (flex-1) — so the
# footer sits at the bottom of a short page instead of floating
# mid-screen, and the page scrolls normally once content overflows.
# Covered on every screen shape the app renders: centered (home, enter)
# and the game screens (waiting and active).
class LayoutShellTest < ActionDispatch::IntegrationTest
  test "home page shell is a full-height flex column with a growing main" do
    get root_path
    assert_response :success

    assert_full_height_shell
  end

  test "enter page shell is a full-height flex column with a growing main" do
    get enter_path
    assert_response :success

    assert_full_height_shell
  end

  test "waiting game shell is a full-height flex column with a growing main" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    get game_path(code: game.code)
    assert_response :success

    assert_full_height_shell
  end

  test "active game shell is a full-height flex column with a growing main" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    get game_path(code: game.code)
    assert_response :success

    assert_full_height_shell
  end

  private

  def assert_full_height_shell
    assert_select "body.min-h-dvh.flex.flex-col"
    assert_select "body > header.shrink-0", count: 1
    assert_select "body > main.flex-1", count: 1
    assert_select "body > footer.shrink-0", count: 1
  end
end
