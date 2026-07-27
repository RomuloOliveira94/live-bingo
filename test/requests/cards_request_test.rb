require "test_helper"

class CardsRequestTest < ActionDispatch::IntegrationTest
  test "guest joins game" do
    game = GameCreator.call

    assert_difference "Card.count", 1 do
      post game_cards_path(game.code)
    end

    assert_response :redirect
    card = Card.last
    assert_equal game, card.game
    assert card.grid_data.present?

    # Check cookie was set
    assert cookies[:bingo_session].present?
  end

  test "guest cannot join finished game" do
    game = GameCreator.call
    game.update!(status: :finished, finished_at: Time.current)

    post game_cards_path(game.code)
    assert_response :gone
  end

  test "host does not auto-join" do
    game = GameCreator.call
    sign_in_as_host(game)

    post game_cards_path(game.code)
    assert_response :not_found
  end

  test "rejoin returns same card" do
    game = GameCreator.call

    post game_cards_path(game.code)
    assert_response :redirect
    card1 = Card.last

    # Sign in again with same guest session
    post game_cards_path(game.code)
    assert_response :redirect

    assert_equal 1, Card.where(game: game).count
  end

  test "join on waiting game works" do
    game = GameCreator.call
    assert_equal "waiting", game.status

    post game_cards_path(game.code)
    assert_response :redirect

    game.reload
    assert_equal "waiting", game.status
    assert_equal 1, game.cards.count
  end
end
