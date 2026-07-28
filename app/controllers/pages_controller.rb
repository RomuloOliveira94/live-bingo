class PagesController < ApplicationController
  def home
  end

  def enter
  end

  def join
    code = params[:code].to_s.upcase.strip
    game = Game.find_by(code: code)
    if game
      redirect_to game_path(code: game.code)
    else
      flash.now[:alert] = t("pages.join.not_found")
      render :enter, status: :unprocessable_entity
    end
  end
end
