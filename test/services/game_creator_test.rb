require "test_helper"

class GameCreatorTest < ActiveSupport::TestCase
  test "creates game with valid attributes" do
    game = GameCreator.call(name: "Test Game", pattern: :line)

    assert game.persisted?
    assert_equal "Test Game", game.name
    assert_equal "line", game.pattern
    assert_equal "waiting", game.status
    assert_equal 6, game.code.length
    assert_match(/\A[A-Z0-9]{6}\z/, game.code)
    assert_equal 32, game.host_session_id.length
    assert_match(/\A[a-f0-9]{32}\z/, game.host_session_id)
  end

  test "creates game with default pattern" do
    game = GameCreator.call

    assert_equal "line", game.pattern
  end

  test "creates game without name" do
    game = GameCreator.call

    assert_nil game.name
    assert game.persisted?
  end
end
