class Card < ApplicationRecord
  # Associations
  belongs_to :game
  has_many :wins, dependent: :destroy

  # Validations
  validates :session_id, presence: true
  validates :grid_data, presence: true
  validate :grid_data_must_be_valid_bingo_card

  # Returns the value at a specific row/column (0-indexed)
  def cell_at(row, col)
    grid_data[row][col]
  end

  # Returns all rows as arrays
  def rows
    grid_data
  end

  # Returns all columns as arrays
  def columns
    grid_data.transpose
  end

  # Returns all numbers on the card that are in the drawn_set
  # FREE is always considered marked
  def marked_numbers(drawn_set)
    drawn_set = drawn_set.is_a?(Set) ? drawn_set : drawn_set.to_set
    marked = []
    grid_data.each_with_index do |row, r|
      row.each_with_index do |cell, c|
        next if cell.to_s == "free"
        marked << cell if drawn_set.include?(cell)
      end
    end
    marked
  end

  # Checks if the card has a winning pattern given the drawn numbers
  # pattern: symbol (:line, :column, :diagonal, :corners, :blackout, :x_pattern)
  # drawn_numbers: Set or Array of integers
  def has_pattern?(pattern, drawn_numbers)
    drawn_set = drawn_numbers.is_a?(Set) ? drawn_numbers : drawn_numbers.to_set

    case pattern.to_sym
    when :line
      check_line(drawn_set)
    when :column
      check_column(drawn_set)
    when :diagonal
      check_diagonal(drawn_set)
    when :corners
      check_corners(drawn_set)
    when :blackout
      check_blackout(drawn_set)
    when :x_pattern
      check_x_pattern(drawn_set)
    else
      false
    end
  end

  private

  def grid_data_must_be_valid_bingo_card
    return if grid_data.blank?

    unless grid_data.is_a?(Array) && grid_data.size == 5
      errors.add(:grid_data, "must be a 5x5 array")
      return
    end

    grid_data.each_with_index do |row, r|
      unless row.is_a?(Array) && row.size == 5
        errors.add(:grid_data, "row #{r} must have 5 elements")
        return
      end

      row.each_with_index do |cell, c|
        next if cell.to_s == "free"

        unless cell.is_a?(Integer)
          errors.add(:grid_data, "cell [#{r}][#{c}] must be an integer or :free")
          return
        end
      end
    end

    # Check FREE is at center (2,2)
    center = grid_data[2][2]
    unless center.to_s == "free"
      errors.add(:grid_data, "center cell [2][2] must be :free")
    end
  end

  def cell_marked?(cell, drawn_set)
    cell.to_s == "free" || drawn_set.include?(cell)
  end

  def check_line(drawn_set)
    # Check if any row is complete
    grid_data.any? do |row|
      row.all? { |cell| cell_marked?(cell, drawn_set) }
    end
  end

  def check_column(drawn_set)
    # Check if any column is complete
    columns.any? do |col|
      col.all? { |cell| cell_marked?(cell, drawn_set) }
    end
  end

  def check_diagonal(drawn_set)
    # Check main diagonal (0,0)(1,1)(2,2)(3,3)(4,4)
    main_diag = (0..4).all? { |i| cell_marked?(grid_data[i][i], drawn_set) }

    # Check anti-diagonal (0,4)(1,3)(2,2)(3,1)(4,0)
    anti_diag = (0..4).all? { |i| cell_marked?(grid_data[i][4 - i], drawn_set) }

    main_diag || anti_diag
  end

  def check_corners(drawn_set)
    # Check all 4 corners: (0,0), (0,4), (4,0), (4,4)
    cell_marked?(grid_data[0][0], drawn_set) &&
      cell_marked?(grid_data[0][4], drawn_set) &&
      cell_marked?(grid_data[4][0], drawn_set) &&
      cell_marked?(grid_data[4][4], drawn_set)
  end

  def check_blackout(drawn_set)
    # All 24 numeric cells must be marked (FREE is auto-marked)
    grid_data.all? do |row|
      row.all? { |cell| cell_marked?(cell, drawn_set) }
    end
  end

  def check_x_pattern(drawn_set)
    # Both diagonals must be complete
    main_diag = (0..4).all? { |i| cell_marked?(grid_data[i][i], drawn_set) }
    anti_diag = (0..4).all? { |i| cell_marked?(grid_data[i][4 - i], drawn_set) }

    main_diag && anti_diag
  end
end
