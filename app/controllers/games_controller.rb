class GamesController < ApplicationController
  FINISHED_REDIRECT_DELAY_MS = 2500

  before_action :load_game, only: [ :show, :start, :finish, :draw, :restart ]
  before_action :require_host!, only: [ :start, :finish, :draw, :restart ]

  def create
    session_data = SessionData.write_new(cookies)
    game = GameCreator.call(host_id: session_data.host_id)
    GameVisitTracker.call(game: game, request: request, visitor_token: session_data.visitor_token, kind: :created)
    redirect_to game_path(code: game.code)
  end

  def show
    raise ActionController::RoutingError, "Game not found" if @game.nil?

    GameVisitTracker.call(game: @game, request: request, visitor_token: current_session&.visitor_token, kind: :joined)
  end

  def start
    @game.update!(status: :active, started_at: Time.current)
    # The waiting/active/finished branches in show.html.erb are mutually
    # exclusive `if`s, never wrapped in a broadcastable target, so a targeted
    # broadcast_replace_to can't flip a guest from one branch to another. A
    # full morphed refresh re-renders the whole page for everyone connected.
    @game.broadcast_refresh_to(@game)
    redirect_to game_path(code: @game.code)
  end

  def finish
    @game.update!(status: :finished, finished_at: Time.current, viewer_count: 0)
    # Deliberately no broadcast_refresh_to here: a full-page morph refresh
    # races with the ephemeral redirect-slot append below (the refresh's
    # fetch resolves against a fresh GET, which has no redirect element, and
    # wipes it out mid-flight). The notice+redirect broadcast already fully
    # resolves the "guest stuck on stale branch" problem by moving everyone
    # off the page entirely, so it doesn't need the refresh's help too.
    broadcast_finished_notice
    redirect_to root_path, notice: t("games.show.finished.message")
  end

  def draw
    DrawService.call(game: @game)
    # No redirect here on purpose: a full-page redirect was the host's own
    # browser tearing down the spin animation and pre-empting the draw sound
    # before either could run (see spin_controller.js, draw_sound_controller.js).
    # The host is subscribed to the same turbo_stream_from @game as every
    # guest (see show.html.erb), so DrawService's own broadcast already
    # updates their DOM — responding with no content lets Turbo settle the
    # form submission in place instead of navigating anywhere.
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { redirect_to game_path(code: @game.code) }
    end
  rescue DrawService::GameNotActive
    respond_with_draw_error(t("draws.errors.game_not_active"))
  rescue DrawService::NoNumbersRemaining
    respond_with_draw_error(t("draws.errors.no_numbers_remaining"))
  end

  def restart
    GameRestarter.call(game: @game)
    @game.broadcast_refresh_to(@game)
    redirect_to game_path(code: @game.code)
  rescue GameRestarter::GameNotActive
    redirect_to game_path(code: @game.code), alert: t("games.errors.game_not_active")
  end

  private

  def load_game
    @game = Game.find_by(code: params[:code])
  end

  def require_host!
    return if Current.host_of?(@game)
    raise ActionController::RoutingError, "Not host"
  end

  # Rejected draw (game not active / no numbers left). Rare in practice — the
  # draw button is hidden/disabled whenever either would be true — but a
  # stale page or a race between two draws can still hit it, and it must
  # surface the same flash message whether or not Turbo intercepted the
  # request.
  def respond_with_draw_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("flash", partial: "layouts/flash", locals: { notice: nil, alert: message })
      end
      format.html { redirect_to game_path(code: @game.code), alert: message }
    end
  end

  # Kicks everyone connected to the game stream out to the home page: shows
  # the "bingo encerrado" notice in the layout's flash region, then appends a
  # redirect element (see redirect_controller.js) that Turbo.visit()s
  # everyone away after a short delay so they have time to read it.
  def broadcast_finished_notice
    Turbo::StreamsChannel.broadcast_update_to(
      @game, target: "flash", partial: "layouts/flash",
             locals: { notice: t("games.show.finished.message"), alert: nil }
    )
    Turbo::StreamsChannel.broadcast_append_to(
      @game, target: "redirect-slot", partial: "games/redirect",
             locals: { url: root_path, delay: FINISHED_REDIRECT_DELAY_MS }
    )
  end
end
