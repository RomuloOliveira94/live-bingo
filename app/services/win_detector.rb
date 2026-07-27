class WinDetector
  def self.call(game, draw) = new(game, draw).call

  def initialize(game, draw)
    @game = game
    @draw = draw
  end

  def call
    drawn_set = @game.draws.pluck(:number).to_set
    cards = @game.cards.to_a
    wins_created = []

    cards.each do |card|
      next unless card.has_pattern?(@game.pattern, drawn_set)

      existing_win = Win.find_by(game: @game, card: card, pattern: @game.pattern)

      if existing_win
        # If existing win is pending or confirmed, skip
        next if existing_win.pending? || existing_win.confirmed?

        # If existing win is cancelled, reactivate it
        if existing_win.cancelled?
          existing_win.update!(status: :pending)
          wins_created << existing_win
        end
      else
        # No existing win, create new one
        win = Win.create!(
          game: @game,
          card: card,
          pattern: @game.pattern,
          status: :pending
        )
        wins_created << win
      end
    end

    wins_created
  end
end
