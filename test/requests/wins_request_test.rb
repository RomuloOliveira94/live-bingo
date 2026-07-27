require "test_helper"

class WinsRequestTest < ActionDispatch::IntegrationTest
  test "host confirms win" do
    game = GameCreator.call
    sign_in_as_host(game)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    patch game_win_path(game.code, win), params: { win: { status: "confirm" } }
    assert_response :redirect

    win.reload
    assert_equal "confirmed", win.status
    assert_not_nil win.confirmed_at
  end

  test "host cancels win" do
    game = GameCreator.call
    sign_in_as_host(game)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    patch game_win_path(game.code, win), params: { win: { status: "cancel" } }
    assert_response :redirect

    win.reload
    assert_equal "cancelled", win.status
  end

  test "guest cannot confirm" do
    game = GameCreator.call
    sign_in_as_guest(game)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    patch game_win_path(game.code, win), params: { win: { status: "confirm" } }
    assert_response :not_found
  end

  test "blackout confirmed finishes game" do
    game = GameCreator.call(pattern: :blackout)
    sign_in_as_host(game)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :blackout, status: :pending)

    patch game_win_path(game.code, win), params: { win: { status: "confirm" } }
    assert_response :redirect

    game.reload
    assert_equal "finished", game.status
    assert_not_nil game.finished_at
  end

  test "non-final pattern does not finish" do
    game = GameCreator.call(pattern: :line)
    sign_in_as_host(game)
    card = game.cards.create!(
      session_id: "guest_123",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    patch game_win_path(game.code, win), params: { win: { status: "confirm" } }
    assert_response :redirect

    game.reload
    assert_equal "waiting", game.status
    assert_nil game.finished_at
  end
end
