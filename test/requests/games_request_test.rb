require "test_helper"

class GamesRequestTest < ActionDispatch::IntegrationTest
  test "host creates game" do
    assert_difference "Game.count", 1 do
      post games_path
    end

    assert_response :redirect
    game = Game.last
    assert_equal "waiting", game.status
    assert cookies[:bingo_session].present?

    follow_redirect!
    assert_response :success
  end

  test "show returns 200 for valid code" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    get game_path(code: game.code)
    assert_response :success
  end

  test "show 404 for invalid code" do
    get game_path(code: "INVALID")
    assert_response :not_found
  end

  test "host can start" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post start_game_path(code: game.code)
    assert_response :redirect

    game.reload
    assert_equal "active", game.status
    assert_not_nil game.started_at
  end

  test "non-host cannot start" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    post start_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can draw number" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    assert_difference "Draw.count", 1 do
      post draw_game_path(code: game.code)
    end

    assert_response :redirect
    draw = Draw.last
    assert_includes 1..75, draw.number
    assert_equal 1, draw.position
  end

  test "non-host cannot draw" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post draw_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can restart" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    game.draws.create!(number: 1, position: 1)
    game.draws.create!(number: 2, position: 2)
    sign_in_as_host(game)

    assert_difference "Draw.count", -2 do
      post restart_game_path(code: game.code)
    end

    assert_response :redirect
  end

  test "non-host cannot restart" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post restart_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can finish" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_host(game)

    post finish_game_path(code: game.code)
    assert_response :redirect

    game.reload
    assert_equal "finished", game.status
    assert_not_nil game.finished_at
  end

  test "non-host cannot finish" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post finish_game_path(code: game.code)
    assert_response :not_found
  end

  test "draw on waiting game rejected" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post draw_game_path(code: game.code)
    assert_response :redirect
    follow_redirect!
    assert flash[:alert].present?
  end
end
