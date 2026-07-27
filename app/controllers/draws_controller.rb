class DrawsController < ApplicationController
  def create
    game = Game.find_by!(code: params[:game_code])

    unless Current.host_of?(game)
      render plain: t("errors.not_host"), status: :not_found
      return
    end

    DrawService.call(game: game)
    redirect_to game_path(game.code)
  rescue DrawService::GameNotActive
    redirect_to game_path(game.code), alert: t("draws.errors.game_not_active")
  rescue DrawService::NoNumbersRemaining
    redirect_to game_path(game.code), alert: t("draws.errors.no_numbers_remaining")
  end
end
