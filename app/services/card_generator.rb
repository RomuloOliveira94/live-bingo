class CardGenerator
  # Returns a 5x5 bingo card array
  # Center cell (2,2) is :free
  # Columns follow 75-ball bingo ranges:
  #   B (col 0): 1-15, I (col 1): 16-30, N (col 2): 31-45,
  #   G (col 3): 46-60, O (col 4): 61-75
  def self.call
    new.call
  end

  def call
    ranges = [
      1..15,   # B
      16..30,  # I
      31..45,  # N
      46..60,  # G
      61..75   # O
    ]

    columns = ranges.map.with_index do |range, col_idx|
      count = col_idx == 2 ? 4 : 5  # N column has 4 numbers (center is FREE)
      range.to_a.sample(count).shuffle
    end

    # Build 5x5 grid
    grid = Array.new(5) { Array.new(5) }

    (0..4).each do |row|
      (0..4).each do |col|
        if row == 2 && col == 2
          grid[row][col] = :free
        else
          # For N column (col 2), skip the FREE slot
          idx = row
          if col == 2
            idx = row < 2 ? row : row - 1
          end
          grid[row][col] = columns[col][idx]
        end
      end
    end

    grid
  end
end
