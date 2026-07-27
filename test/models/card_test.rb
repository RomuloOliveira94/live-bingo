require "test_helper"

class CardTest < ActiveSupport::TestCase
  # Associations
  test "should belong to game" do
    card = cards(:one)
    assert_respond_to card, :game
  end

  test "should have many wins" do
    card = cards(:one)
    assert_respond_to card, :wins
  end

  # Validations
  test "should be valid with valid attributes" do
    card = Card.new(game: games(:one), session_id: "session123", grid_data: valid_grid)
    assert card.valid?
  end

  test "should require session_id" do
    card = Card.new(game: games(:one), grid_data: valid_grid)
    assert_not card.valid?
    assert_includes card.errors[:session_id], "can't be blank"
  end

  test "should require grid_data" do
    card = Card.new(game: games(:one), session_id: "session123")
    assert_not card.valid?
    assert_includes card.errors[:grid_data], "can't be blank"
  end

  test "should validate grid_data structure" do
    card = Card.new(game: games(:one), session_id: "session123", grid_data: [[1, 2], [3, 4]])
    assert_not card.valid?
    assert card.errors[:grid_data].any?
  end

  test "should validate FREE at center" do
    grid = valid_grid
    grid[2][2] = 99
    card = Card.new(game: games(:one), session_id: "session123", grid_data: grid)
    assert_not card.valid?
    assert_includes card.errors[:grid_data], "center cell [2][2] must be :free"
  end

  # Instance methods
  test "cell_at returns correct value" do
    card = cards(:one)
    assert_equal 1, card.cell_at(0, 0)
    assert_equal "free", card.cell_at(2, 2)
    assert_equal 65, card.cell_at(4, 4)
  end

  test "rows returns grid_data" do
    card = cards(:one)
    assert_equal card.grid_data, card.rows
  end

  test "columns returns transposed grid" do
    card = cards(:one)
    cols = card.columns
    assert_equal 5, cols.size
    assert_equal [1, 2, 3, 4, 5], cols[0]
  end

  test "marked_numbers returns marked cells" do
    card = cards(:one)
    drawn = Set.new([1, 2, 3, 4, 5])
    marked = card.marked_numbers(drawn)
    assert_includes marked, 1
    assert_includes marked, 2
    assert_equal 5, marked.size
  end

  # Pattern tests
  test "line win - middle row with FREE" do
    card = cards(:one)
    # Middle row: [3, 18, :free, 48, 63]
    drawn = Set.new([3, 18, 48, 63])
    assert card.has_pattern?(:line, drawn)
  end

  test "line win - other row" do
    card = cards(:one)
    # First row: [1, 16, 31, 46, 61]
    drawn = Set.new([1, 16, 31, 46, 61])
    assert card.has_pattern?(:line, drawn)
  end

  test "line no win" do
    card = cards(:one)
    drawn = Set.new([1, 16, 31, 46])  # Missing 61
    assert_not card.has_pattern?(:line, drawn)
  end

  test "column win - first column" do
    card = cards(:one)
    # First column: [1, 2, 3, 4, 5]
    drawn = Set.new([1, 2, 3, 4, 5])
    assert card.has_pattern?(:column, drawn)
  end

  test "column win - N column with FREE" do
    card = cards(:one)
    # N column: [31, 32, :free, 33, 34]
    drawn = Set.new([31, 32, 33, 34])
    assert card.has_pattern?(:column, drawn)
  end

  test "column no win" do
    card = cards(:one)
    drawn = Set.new([1, 2, 3, 4])  # Missing 5
    assert_not card.has_pattern?(:column, drawn)
  end

  test "diagonal win - main diagonal" do
    card = cards(:one)
    # Main diagonal: [1, 17, :free, 49, 65]
    drawn = Set.new([1, 17, 49, 65])
    assert card.has_pattern?(:diagonal, drawn)
  end

  test "diagonal win - anti diagonal" do
    card = cards(:one)
    # Anti diagonal: [61, 47, :free, 19, 5]
    drawn = Set.new([61, 47, 19, 5])
    assert card.has_pattern?(:diagonal, drawn)
  end

  test "diagonal no win" do
    card = cards(:one)
    drawn = Set.new([1, 17, 49])  # Missing 65
    assert_not card.has_pattern?(:diagonal, drawn)
  end

  test "corners win" do
    card = cards(:one)
    # Corners: [1, 61, 5, 65]
    drawn = Set.new([1, 61, 5, 65])
    assert card.has_pattern?(:corners, drawn)
  end

  test "corners no win" do
    card = cards(:one)
    drawn = Set.new([1, 61, 5])  # Missing 65
    assert_not card.has_pattern?(:corners, drawn)
  end

  test "blackout win" do
    card = cards(:one)
    # All 24 numbers
    drawn = Set.new([1, 2, 3, 4, 5, 16, 17, 18, 19, 20, 31, 32, 33, 34, 46, 47, 48, 49, 50, 61, 62, 63, 64, 65])
    assert card.has_pattern?(:blackout, drawn)
  end

  test "blackout no win" do
    card = cards(:one)
    drawn = Set.new([1, 2, 3, 4, 5, 16, 17, 18, 19, 20, 31, 32, 33, 34, 46, 47, 48, 49, 50, 61, 62, 63, 64])  # Missing 65
    assert_not card.has_pattern?(:blackout, drawn)
  end

  test "x_pattern win" do
    card = cards(:one)
    # Both diagonals: [1, 17, 49, 65, 61, 47, 19, 5]
    drawn = Set.new([1, 17, 49, 65, 61, 47, 19, 5])
    assert card.has_pattern?(:x_pattern, drawn)
  end

  test "x_pattern no win - only one diagonal" do
    card = cards(:one)
    drawn = Set.new([1, 17, 49, 65])  # Only main diagonal
    assert_not card.has_pattern?(:x_pattern, drawn)
  end

  test "unknown pattern returns false" do
    card = cards(:one)
    drawn = Set.new([1, 2, 3])
    assert_not card.has_pattern?(:unknown, drawn)
  end

  private

  def valid_grid
    [
      [1, 16, 31, 46, 61],
      [2, 17, 32, 47, 62],
      [3, 18, :free, 48, 63],
      [4, 19, 33, 49, 64],
      [5, 20, 34, 50, 65]
    ]
  end
end
