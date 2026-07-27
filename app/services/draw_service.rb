class DrawService
  class GameNotActive < StandardError; end
  class NoNumbersRemaining < StandardError; end

  def self.call(game:) = new(game: game).call

  def initialize(game:)
    @game = game
  end

  def call
    raise GameNotActive, "Game is not active" unless @game.active?

    drawn_numbers = @game.draws.pluck(:number).to_set
    remaining = (1..75).to_a - drawn_numbers.to_a
    raise NoNumbersRemaining, "All 75 numbers have been drawn" if remaining.empty?

    number = remaining.sample
    position = @game.draws.maximum(:position).to_i + 1

    ActiveRecord::Base.transaction do
      draw = @game.draws.create!(number: number, position: position)
      WinDetector.call(@game, draw)
      draw
    end
  end
end
