require "test_helper"

class GamesRequestTest < ActionDispatch::IntegrationTest
  test "host creates game" do
    assert_difference "Game.count", 1 do
      post games_path, params: { name: "Test Game", pattern: "line" }
    end

    assert_response :redirect
    game = Game.last
    assert_equal "Test Game", game.name
    assert_equal "line", game.pattern
    assert_equal "waiting", game.status

    # Check cookie was set
    assert cookies[:bingo_session].present?
  end

  test "new renders form" do
    get new_game_path
    assert_response :success
    assert_select "form"
    assert_select "select[name='pattern']"
  end

  test "show waiting for host" do
    game = GameCreator.call(name: "Test")
    sign_in_as_host(game)

    get game_path(game.code)
    assert_response :success
    assert_select "#game-status", text: "Aguardando"
    assert_select "#host-controls"
  end

  test "show 404 for invalid code" do
    get game_path("INVALID")
    assert_response :not_found
  end

  test "guest cannot start" do
    game = GameCreator.call
    sign_in_as_guest(game)

    post start_game_path(game.code)
    assert_response :not_found
  end

  test "host can start" do
    game = GameCreator.call
    sign_in_as_host(game)

    post start_game_path(game.code)
    assert_response :redirect

    game.reload
    assert_equal "active", game.status
    assert_not_nil game.started_at
  end

  test "only host can finish" do
    game = GameCreator.call
    game.update!(status: :active)
    sign_in_as_guest(game)

    post finish_game_path(game.code)
    assert_response :not_found
  end

  test "show finished page renders winners" do
    game = GameCreator.call
    game.update!(status: :finished, finished_at: Time.current)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    Win.create!(game: game, card: card, pattern: :line, status: :confirmed, confirmed_at: Time.current)

    get game_path(game.code)
    assert_response :success
    assert_select "#winners"
    assert_select "#winners li", count: 1
  end
end
