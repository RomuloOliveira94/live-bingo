require "test_helper"

class WinTest < ActiveSupport::TestCase
  # Associations
  test "should belong to game" do
    win = wins(:one)
    assert_respond_to win, :game
  end

  test "should belong to card" do
    win = wins(:one)
    assert_respond_to win, :card
  end

  # Enums
  test "should define pattern enum" do
    assert Win.patterns.keys == %w[line column diagonal corners blackout x_pattern]
  end

  test "should define status enum" do
    assert Win.statuses.keys == %w[pending confirmed cancelled]
  end

  test "pattern enum methods work" do
    win = wins(:one)
    assert win.line?
    win.column!
    assert win.column?
  end

  test "status enum methods work" do
    win = wins(:one)
    assert win.pending?
    win.confirmed!
    assert win.confirmed?
  end

  # Validations
  test "should be valid with valid attributes" do
    win = Win.new(game: games(:one), card: cards(:one), pattern: :line, status: :pending)
    assert win.valid?
  end

  test "should require pattern" do
    win = Win.new(game: games(:one), card: cards(:one), status: :pending)
    win.pattern = nil
    assert_not win.valid?
  end

  test "should require status" do
    win = Win.new(game: games(:one), card: cards(:one), pattern: :line)
    win.status = nil
    assert_not win.valid?
  end

  test "unique index on game_id + card_id + pattern" do
    win1 = wins(:one)
    win2 = Win.new(game: win1.game, card: win1.card, pattern: win1.pattern, status: :pending)
    assert_raises(ActiveRecord::RecordNotUnique) do
      win2.save(validate: false)
    end
  end
end
