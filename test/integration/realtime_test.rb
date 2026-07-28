require "test_helper"

class RealtimeTest < ActionDispatch::IntegrationTest
  test "draw completes successfully" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    assert_difference "Draw.count", 1 do
      post draw_game_path(code: game.code)
    end
    assert_response :redirect
  end

  test "restart clears draws" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    game.draws.create!(number: 1, position: 1)
    sign_in_as_host(game)

    assert_difference "Draw.count", -1 do
      post restart_game_path(code: game.code)
    end
    assert_response :redirect
  end

  test "game start completes successfully" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post start_game_path(code: game.code)
    assert_response :redirect

    game.reload
    assert_equal "active", game.status
  end

  test "game finish completes successfully" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_host(game)

    post finish_game_path(code: game.code)
    assert_response :redirect

    game.reload
    assert_equal "finished", game.status
  end
end
