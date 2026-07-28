require "test_helper"

class GameCreatorTest < ActiveSupport::TestCase
  test "creates game with host_id" do
    host_id = SecureRandom.hex(16)
    game = GameCreator.call(host_id: host_id)

    assert game.persisted?
    assert_equal host_id, game.host_session_id
    assert_equal "waiting", game.status
    assert_equal 6, game.code.length
    assert_match(/\A[A-Z0-9]{6}\z/, game.code)
    assert_equal 0, game.viewer_count
  end

  test "creates game with generated host_id" do
    host_id = SessionData.host_id_for_new_game
    game = GameCreator.call(host_id: host_id)

    assert game.persisted?
    assert_equal 32, game.host_session_id.length
  end
end
