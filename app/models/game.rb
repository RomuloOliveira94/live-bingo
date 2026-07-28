class Game < ApplicationRecord
  # Associations
  has_many :draws, dependent: :destroy

  # Enums
  enum :status, { waiting: 0, active: 1, finished: 2 }

  # Validations
  validates :code, presence: true, uniqueness: true, length: { is: 6 },
                   format: { with: /\A[A-Z0-9]{6}\z/ }
  validates :host_session_id, presence: true
  validates :status, presence: true

  # Callbacks
  before_validation :generate_code, on: :create

  private

  def generate_code
    return if code.present?

    # Exclude ambiguous characters: 0, O, 1, I, L
    safe_chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
    5.times do
      self.code = Array.new(6) { safe_chars.chars.sample }.join
      return unless self.class.exists?(code: code)
    end
    raise "Failed to generate unique code after 5 attempts"
  end
end
