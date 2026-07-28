require "test_helper"

class GameRestarterTest < ActiveSupport::TestCase
  test "clears all draws for active game" do
    game = games(:two) # active
    game.draws.create!(number: 1, position: 1)
    game.draws.create!(number: 2, position: 2)
    assert_equal 2, game.draws.count

    GameRestarter.call(game: game)

    assert_equal 0, game.draws.count
  end

  test "raises GameNotActive for waiting game" do
    game = games(:one) # waiting

    assert_raises(GameRestarter::GameNotActive) do
      GameRestarter.call(game: game)
    end
  end

  test "raises GameNotActive for finished game" do
    game = games(:one)
    game.update!(status: :finished)

    assert_raises(GameRestarter::GameNotActive) do
      GameRestarter.call(game: game)
    end
  end
end
