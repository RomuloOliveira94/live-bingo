class Win < ApplicationRecord
  belongs_to :game
  belongs_to :card

  enum :pattern, { line: 0, column: 1, diagonal: 2, corners: 3, blackout: 4, x_pattern: 5 }
  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }

  validates :pattern, :status, presence: true
end
