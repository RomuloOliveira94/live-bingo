require "test_helper"

class DrawTest < ActiveSupport::TestCase
  # Associations
  test "should belong to game" do
    draw = draws(:one)
    assert_respond_to draw, :game
  end

  # Validations
  test "should be valid with valid attributes" do
    draw = Draw.new(game: games(:one), number: 42, position: 1)
    assert draw.valid?
  end

  test "should require number" do
    draw = Draw.new(game: games(:one), position: 1)
    assert_not draw.valid?
    assert_includes draw.errors[:number], "não pode ficar em branco"
  end

  test "should require number to be integer" do
    draw = Draw.new(game: games(:one), number: 1.5, position: 1)
    assert_not draw.valid?
  end

  test "should require number in range 1..75" do
    draw_low = Draw.new(game: games(:one), number: 0, position: 1)
    assert_not draw_low.valid?
    assert_includes draw_low.errors[:number], "deve estar entre 1..75"

    draw_high = Draw.new(game: games(:one), number: 76, position: 1)
    assert_not draw_high.valid?
    assert_includes draw_high.errors[:number], "deve estar entre 1..75"
  end

  test "should require position" do
    draw = Draw.new(game: games(:one), number: 42)
    assert_not draw.valid?
    assert_includes draw.errors[:position], "não pode ficar em branco"
  end

  test "should require position to be integer" do
    draw = Draw.new(game: games(:one), number: 42, position: 1.5)
    assert_not draw.valid?
  end

  test "should require position greater than 0" do
    draw = Draw.new(game: games(:one), number: 42, position: 0)
    assert_not draw.valid?
    assert draw.errors[:position].any?
  end

  test "unique index on game_id + number" do
    draw1 = draws(:one)
    draw2 = Draw.new(game: draw1.game, number: draw1.number, position: 999)
    assert_raises(ActiveRecord::RecordNotUnique) do
      draw2.save(validate: false)
    end
  end
end
