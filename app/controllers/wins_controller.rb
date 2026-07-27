class WinsController < ApplicationController
  def update
    game = Game.find_by!(code: params[:game_code])
    win = Win.find(params[:id])

    unless Current.host_of?(game)
      render plain: t("errors.not_host"), status: :not_found
      return
    end

    action = params[:win][:status] == "cancel" ? :cancel : :confirm
    WinConfirmer.call(win: win, action: action)
    redirect_to game_path(game.code)
  end
end
