require "test_helper"

class WinConfirmerTest < ActiveSupport::TestCase
  test "confirms win" do
    game = GameCreator.call
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    result = WinConfirmer.call(win: win, action: :confirm)

    assert_equal "confirmed", result.status
    assert_not_nil result.confirmed_at
  end

  test "cancels win" do
    game = GameCreator.call
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    result = WinConfirmer.call(win: win, action: :cancel)

    assert_equal "cancelled", result.status
  end

  test "blackout pattern finishes game" do
    game = GameCreator.call(pattern: :blackout)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :blackout, status: :pending)

    WinConfirmer.call(win: win, action: :confirm)

    game.reload
    assert_equal "finished", game.status
    assert_not_nil game.finished_at
  end

  test "non-blackout pattern does not finish game" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [ [ 1, 16, 31, 46, 61 ], [ 2, 17, 32, 47, 62 ], [ 3, 18, "free", 48, 63 ], [ 4, 19, 33, 49, 64 ], [ 5, 20, 34, 50, 65 ] ]
    )
    win = Win.create!(game: game, card: card, pattern: :line, status: :pending)

    WinConfirmer.call(win: win, action: :confirm)

    game.reload
    assert_equal "waiting", game.status
    assert_nil game.finished_at
  end
end
