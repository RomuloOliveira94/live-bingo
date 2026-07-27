class Draw < ApplicationRecord
  belongs_to :game

  validates :number, presence: true, numericality: { only_integer: true, in: 1..75 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
