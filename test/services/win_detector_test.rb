require "test_helper"

class WinDetectorTest < ActiveSupport::TestCase
  test "creates win when card has pattern" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Draw numbers to complete first row
    draw = game.draws.create!(number: 61, position: 1)
    game.draws.create!(number: 1, position: 2)
    game.draws.create!(number: 16, position: 3)
    game.draws.create!(number: 31, position: 4)
    game.draws.create!(number: 46, position: 5)

    wins = WinDetector.call(game, draw)

    assert_equal 1, wins.length
    assert_equal card, wins.first.card
    assert_equal "line", wins.first.pattern
    assert_equal "pending", wins.first.status
  end

  test "does not create win when card lacks pattern" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Draw only 4 numbers (incomplete row)
    draw = game.draws.create!(number: 1, position: 1)
    game.draws.create!(number: 16, position: 2)
    game.draws.create!(number: 31, position: 3)
    game.draws.create!(number: 46, position: 4)

    wins = WinDetector.call(game, draw)

    assert_empty wins
  end

  test "does not duplicate existing pending win" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Create existing pending win
    Win.create!(game: game, card: card, pattern: :line, status: :pending)

    # Draw numbers to complete first row
    draw = game.draws.create!(number: 61, position: 1)
    game.draws.create!(number: 1, position: 2)
    game.draws.create!(number: 16, position: 3)
    game.draws.create!(number: 31, position: 4)
    game.draws.create!(number: 46, position: 5)

    wins = WinDetector.call(game, draw)

    assert_empty wins
    assert_equal 1, Win.where(game: game, card: card, pattern: "line").count
  end

  test "does not duplicate existing confirmed win" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Create existing confirmed win
    Win.create!(game: game, card: card, pattern: :line, status: :confirmed, confirmed_at: Time.current)

    # Draw numbers to complete first row
    draw = game.draws.create!(number: 61, position: 1)
    game.draws.create!(number: 1, position: 2)
    game.draws.create!(number: 16, position: 3)
    game.draws.create!(number: 31, position: 4)
    game.draws.create!(number: 46, position: 5)

    wins = WinDetector.call(game, draw)

    assert_empty wins
    assert_equal 1, Win.where(game: game, card: card, pattern: "line").count
  end

  test "reactivates cancelled win" do
    game = GameCreator.call(pattern: :line)
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Create existing cancelled win
    existing_win = Win.create!(game: game, card: card, pattern: :line, status: :cancelled)

    # Draw numbers to complete first row
    draw = game.draws.create!(number: 61, position: 1)
    game.draws.create!(number: 1, position: 2)
    game.draws.create!(number: 16, position: 3)
    game.draws.create!(number: 31, position: 4)
    game.draws.create!(number: 46, position: 5)

    wins = WinDetector.call(game, draw)

    assert_equal 1, wins.length
    assert_equal existing_win.id, wins.first.id
    assert_equal "pending", wins.first.status
    assert_equal 1, Win.where(game: game, card: card, pattern: "line").count
  end

  test "avoids N+1 queries with multiple cards" do
    game = GameCreator.call(pattern: :line)

    # Create 6 cards that will all win with line pattern
    6.times do |i|
      game.cards.create!(
        session_id: "test_guest_#{i}",
        grid_data: [
          [ 1, 16, 31, 46, 61 ],
          [ 2, 17, 32, 47, 62 ],
          [ 3, 18, "free", 48, 63 ],
          [ 4, 19, 33, 49, 64 ],
          [ 5, 20, 34, 50, 65 ]
        ]
      )
    end

    # Draw numbers to complete first row
    draw = game.draws.create!(number: 61, position: 1)
    game.draws.create!(number: 1, position: 2)
    game.draws.create!(number: 16, position: 3)
    game.draws.create!(number: 31, position: 4)
    game.draws.create!(number: 46, position: 5)

    # Count SELECT queries on wins table - should be 1 (bulk load), not N (one per card)
    win_select_queries = 0
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload[:sql]
      win_select_queries += 1 if sql.include?("wins") && sql.include?("SELECT") && !sql.include?("SCHEMA")
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      WinDetector.call(game, draw)
    end

    # Should be exactly 1 SELECT on wins (the bulk load), not 6+ (one per card)
    assert_equal 1, win_select_queries, "Expected 1 SELECT on wins (bulk load), got #{win_select_queries}"
  end
end
