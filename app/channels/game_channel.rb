class GameChannel < ApplicationCable::Channel
  def subscribed
    @game = Game.find_by(code: params[:code])
    return reject unless @game

    stream_for @game
    @game.with_lock { @game.increment!(:viewer_count) }
    broadcast_viewer_count
  end

  def unsubscribed
    return unless @game
    begin
      @game.with_lock do
        @game.decrement!(:viewer_count) if @game.viewer_count > 0
      end
      broadcast_viewer_count
    rescue ActiveRecord::RecordNotFound
      # Game was deleted, ignore
    end
  end

  private

  def broadcast_viewer_count
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "viewer-count", partial: "games/viewer_count", locals: { game: @game.reload }
    )
  end
end
