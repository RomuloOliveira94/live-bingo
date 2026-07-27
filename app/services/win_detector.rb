class WinDetector
  def self.call(game, draw) = new(game, draw).call

  def initialize(game, draw)
    @game = game
    @draw = draw
  end

  def call
    drawn_set = @game.draws.pluck(:number).to_set
    wins_by_card = Win.where(game: @game, pattern: @game.pattern).group_by(&:card_id)
    new_wins = []

    @game.cards.find_each do |card|
      next unless card.has_pattern?(@game.pattern, drawn_set)

      existing = wins_by_card[card.id]&.first

      if existing
        # If existing win is pending or confirmed, skip
        next if existing.pending? || existing.confirmed?

        # If existing win is cancelled, reactivate it
        if existing.cancelled?
          existing.update!(status: :pending)
          new_wins << existing
        end
      else
        # No existing win, create new one
        win = Win.create!(
          game: @game,
          card: card,
          pattern: @game.pattern,
          status: :pending
        )
        new_wins << win
      end
    end

    new_wins
  end
end
