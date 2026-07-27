class CardJoiner
  class GameAlreadyFinished < StandardError; end

  def self.call(game:, guest_session_id:) = new(game: game, guest_session_id: guest_session_id).call

  def initialize(game:, guest_session_id:)
    @game = game
    @guest_session_id = guest_session_id
  end

  def call
    raise GameAlreadyFinished, "Game is already finished" if @game.finished?

    Card.find_or_create_by!(game: @game, session_id: @guest_session_id) do |card|
      card.grid_data = CardGenerator.call
    end
  end
end
