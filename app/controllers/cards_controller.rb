class CardsController < ApplicationController
  def create
    game = Game.find_by!(code: params[:game_code])

    if Current.host_of?(game)
      render plain: t("cards.errors.host_cannot_join"), status: :not_found
      return
    end

    # Check if already a guest for this game
    if Current.guest? && Current.game_id == game.id
      # Already joined, just redirect
      redirect_to game_path(game.code)
      return
    end

    guest_session_id = SecureRandom.hex(16)
    CardJoiner.call(game: game, guest_session_id: guest_session_id)
    set_session_cookie(SessionData.guest_for(game, session_id: guest_session_id))
    redirect_to game_path(game.code)
  rescue CardJoiner::GameAlreadyFinished
    render plain: t("cards.errors.game_finished"), status: :gone
  end
end
