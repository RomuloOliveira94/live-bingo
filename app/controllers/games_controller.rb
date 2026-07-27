class GamesController < ApplicationController
  before_action :load_game, only: [ :show, :start, :finish ]

  def new
  end

  def create
    @game = GameCreator.call(name: params[:name], pattern: params[:pattern] || :line)
    set_session_cookie(SessionData.host_for(@game))
    redirect_to game_path(@game.code)
  end

  def show
    if @game.nil?
      render plain: t("errors.game_not_found"), status: :not_found
      return
    end

    if Current.guest? && Current.game_id == @game.id
      @card = Card.find_by(game: @game, session_id: Current.guest_session_id)
      if @card.nil?
        render plain: t("errors.card_not_found"), status: :not_found
        return
      end
    end

    if @game.finished?
      @wins = @game.wins.confirmed.includes(:card)
    end
  end

  def start
    unless Current.host_of?(@game)
      render plain: t("errors.not_host"), status: :not_found
      return
    end

    @game.update!(status: :active, started_at: Time.current)
    redirect_to game_path(@game.code)
  end

  def finish
    unless Current.host_of?(@game)
      render plain: t("errors.not_host"), status: :not_found
      return
    end

    @game.update!(status: :finished, finished_at: Time.current)
    redirect_to game_path(@game.code)
  end

  private

  def load_game
    @game = Game.find_by(code: params[:code])
  end
end
