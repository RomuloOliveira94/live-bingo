class GameVisit < ApplicationRecord
  belongs_to :game

  # Enums
  enum :kind, { created: 0, joined: 1 }
  enum :device_type, { desktop: 0, mobile: 1, tablet: 2, unknown: 3 }

  # Validations
  validates :visitor_token, presence: true
  validates :kind, presence: true
  validates :device_type, presence: true
end
