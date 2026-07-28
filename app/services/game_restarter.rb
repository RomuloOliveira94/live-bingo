class GameRestarter
  class GameNotActive < StandardError; end

  def self.call(game:) = new(game).call

  def initialize(game)
    @game = game
  end

  def call
    raise GameNotActive, "Game is not active" unless @game.active?

    @game.draws.destroy_all
    broadcast_restart
  end

  private

  def broadcast_restart
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "last-ball", partial: "games/last_ball", locals: { draw: nil }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "draw-history", partial: "games/draw_history", locals: { draws: @game.draws.order(position: :desc) }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "drawn-count", partial: "games/drawn_count", locals: { game: @game }
    )
  end
end
