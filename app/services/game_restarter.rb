class GameRestarter
  class GameNotActive < StandardError; end

  def self.call(game:) = new(game).call

  def initialize(game)
    @game = game
  end

  def call
    raise GameNotActive, "Game is not active" unless @game.active?

    @game.draws.destroy_all
    # Reset the presence counter too: a restart is a fresh start for the
    # room, and this keeps abandoned/crashed subscriptions (which never got
    # to send their decrement) from leaving a permanent upward drift.
    @game.update!(viewer_count: 0)
    broadcast_restart
  end

  private

  def broadcast_restart
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "last-ball", partial: "games/last_ball", locals: { draw: nil }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "draw-history", partial: "games/draw_history",
      locals: { draws: @game.draws.order(position: :desc).limit(5) }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "drawn-count", partial: "games/drawn_count", locals: { game: @game }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "board", partial: "games/board", locals: { game: @game }
    )
  end
end
