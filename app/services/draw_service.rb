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

  # Renders games/draw_broadcast.turbo_stream.erb — the same template
  # GamesController#draw renders inline for its own actor (see that
  # action's comment) — so guests and the host's own broadcast copy always
  # get exactly the same set of updates.
  def broadcast_draw(draw)
    Turbo::StreamsChannel.broadcast_render_to(
      @game, template: "games/draw_broadcast", locals: { game: @game, draw: draw }
    )
  end
end
