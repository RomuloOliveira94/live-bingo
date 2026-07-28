class GamesController < ApplicationController
  before_action :load_game, only: [ :show, :start, :finish, :draw, :restart ]
  before_action :require_host!, only: [ :start, :finish, :draw, :restart ]

  def create
    session_data = SessionData.write_new(cookies)
    game = GameCreator.call(host_id: session_data.host_id)
    redirect_to game_path(code: game.code)
  end

  def show
    raise ActionController::RoutingError, "Game not found" if @game.nil?
  end

  def start
    @game.update!(status: :active, started_at: Time.current)
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "game-status", partial: "games/status_badge", locals: { game: @game }
    )
    redirect_to game_path(code: @game.code)
  end

  def finish
    @game.update!(status: :finished, finished_at: Time.current)
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "game-status", partial: "games/status_badge", locals: { game: @game }
    )
    last_draw = @game.draws.order(position: :desc).first
    Turbo::StreamsChannel.broadcast_replace_to(
      @game, target: "last-ball", partial: "games/last_ball", locals: { draw: last_draw }
    )
    redirect_to game_path(code: @game.code)
  end

  def draw
    DrawService.call(game: @game)
    redirect_to game_path(code: @game.code)
  rescue DrawService::GameNotActive
    redirect_to game_path(code: @game.code), alert: t("draws.errors.game_not_active")
  rescue DrawService::NoNumbersRemaining
    redirect_to game_path(code: @game.code), alert: t("draws.errors.no_numbers_remaining")
  end

  def restart
    GameRestarter.call(game: @game)
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
end
