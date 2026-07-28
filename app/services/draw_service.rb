class DrawService
  class GameNotActive < StandardError; end
  class NoNumbersRemaining < StandardError; end

  def self.call(game:) = new(game).call

  def initialize(game)
    @game = game
  end

  def call
    raise GameNotActive, "Game is not active" unless @game.active?

    drawn_numbers = @game.draws.pluck(:number).to_set
    remaining = (1..75).to_a - drawn_numbers.to_a
    raise NoNumbersRemaining, "All 75 numbers have been drawn" if remaining.empty?

    number = remaining.sample
    position = @game.draws.maximum(:position).to_i + 1

    draw = nil
    ActiveRecord::Base.transaction do
      draw = @game.draws.create!(number: number, position: position)
    end
    broadcast_draw(draw)
    draw
  end

  private

  def broadcast_draw(draw)
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "last-ball", partial: "games/last_ball", locals: { draw: draw }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "draw-history", partial: "games/draw_history",
      locals: { draws: @game.draws.order(position: :desc) }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "drawn-count", partial: "games/drawn_count", locals: { game: @game }
    )
  end
end
