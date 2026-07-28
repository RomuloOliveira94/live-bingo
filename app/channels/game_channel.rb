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

  # Broadcasts ONLY the raw number — never rendered/translated text. This
  # runs in an Action Cable worker thread, entirely outside any request, so
  # there is no per-request locale to render with (see LocaleResolver /
  # ApplicationController#set_locale) — rendering the pluralized label here
  # would always come out at config.i18n.default_locale (pt-BR), regardless
  # of any given subscriber's own resolved locale. See
  # games/_viewer_count.html.erb / viewer_count_controller.js for how each
  # subscriber's own already-localized label reacts to this.
  def broadcast_viewer_count
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "viewer-count-value", html: @game.reload.viewer_count.to_s
    )
  end
end
