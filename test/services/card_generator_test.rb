require "test_helper"

class CardGeneratorTest < ActiveSupport::TestCase
  test "returns 5x5 array" do
    grid = CardGenerator.call
    assert_equal 5, grid.size
    grid.each do |row|
      assert_equal 5, row.size
    end
  end

  test "FREE at center (2,2)" do
    grid = CardGenerator.call
    assert_equal :free, grid[2][2]
  end

  test "FREE only at center" do
    grid = CardGenerator.call
    grid.each_with_index do |row, r|
      row.each_with_index do |cell, c|
        if r == 2 && c == 2
          assert_equal :free, cell
        else
          assert_not_equal :free, cell
          assert cell.is_a?(Integer)
        end
      end
    end
  end

  test "column 0 (B) values in 1..15" do
    grid = CardGenerator.call
    col = grid.map { |row| row[0] }
    col.each do |val|
      assert_includes 1..15, val
    end
  end

  test "column 1 (I) values in 16..30" do
    grid = CardGenerator.call
    col = grid.map { |row| row[1] }
    col.each do |val|
      assert_includes 16..30, val
    end
  end

  test "column 2 (N) values in 31..45 (excluding FREE)" do
    grid = CardGenerator.call
    col = grid.map.with_index { |row, r| row[2] unless r == 2 }.compact
    col.each do |val|
      assert_includes 31..45, val
    end
  end

  test "column 3 (G) values in 46..60" do
    grid = CardGenerator.call
    col = grid.map { |row| row[3] }
    col.each do |val|
      assert_includes 46..60, val
    end
  end

  test "column 4 (O) values in 61..75" do
    grid = CardGenerator.call
    col = grid.map { |row| row[4] }
    col.each do |val|
      assert_includes 61..75, val
    end
  end

  test "no duplicates in any column" do
    grid = CardGenerator.call
    (0..4).each do |col_idx|
      col = grid.map.with_index { |row, r| row[col_idx] unless r == 2 && col_idx == 2 }.compact
      assert_equal col.uniq.size, col.size, "Column #{col_idx} has duplicates"
    end
  end

  test "column 2 has exactly 4 numbers + FREE" do
    grid = CardGenerator.call
    col = grid.map { |row| row[2] }
    numbers = col.reject { |c| c == :free }
    assert_equal 4, numbers.size
    assert_equal 1, col.count(:free)
  end

  test "other columns have exactly 5 numbers" do
    grid = CardGenerator.call
    [0, 1, 3, 4].each do |col_idx|
      col = grid.map { |row| row[col_idx] }
      assert_equal 5, col.size
      assert col.all? { |c| c.is_a?(Integer) }
    end
  end

  test "1000 cards generated with 0 violations" do
    1000.times do
      grid = CardGenerator.call

      # Check structure
      assert_equal 5, grid.size
      grid.each { |row| assert_equal 5, row.size }

      # Check FREE
      assert_equal :free, grid[2][2]

      # Check ranges
      assert grid.all? { |row| (1..15).include?(row[0]) }
      assert grid.all? { |row| (16..30).include?(row[1]) }
      assert grid.each_with_index.all? { |row, r| r == 2 ? true : (31..45).include?(row[2]) }
      assert grid.all? { |row| (46..60).include?(row[3]) }
      assert grid.all? { |row| (61..75).include?(row[4]) }

      # Check no duplicates in columns
      (0..4).each do |col_idx|
        col = grid.map.with_index { |row, r| row[col_idx] unless r == 2 && col_idx == 2 }.compact
        assert_equal col.uniq.size, col.size
      end
    end
  end
end
