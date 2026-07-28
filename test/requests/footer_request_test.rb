require "test_helper"

# Site-wide footer (Part D): rendered in the shared layout, so every page
# gets it — home, enter, and every game screen alike (see
# layouts/_footer.html.erb, rendered from layouts/application.html.erb).
class FooterRequestTest < ActionDispatch::IntegrationTest
  test "home page renders the footer with the author link" do
    get root_path
    assert_response :success

    assert_footer_author_link
  end

  test "enter page renders the footer with the author link" do
    get enter_path
    assert_response :success

    assert_footer_author_link
  end

  test "a game page renders the footer with the author link" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    get game_path(code: game.code)
    assert_response :success

    assert_footer_author_link
  end

  private

  def assert_footer_author_link
    assert_select "footer" do
      assert_select "a[href=?][target=?][rel=?]",
        Rails.application.config.x.app.author_github_url, "_blank", "noopener",
        text: I18n.t("layout.footer.author")
    end
  end
end
