require "test_helper"

class DrawsRequestTest < ActionDispatch::IntegrationTest
  test "host draws number" do
    game = GameCreator.call
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    assert_difference "Draw.count", 1 do
      post game_draws_path(game.code)
    end

    assert_response :redirect
    draw = Draw.last
    assert_includes 1..75, draw.number
    assert_equal 1, draw.position
  end

  test "guest cannot draw" do
    game = GameCreator.call
    game.update!(status: :active)
    sign_in_as_guest(game)

    post game_draws_path(game.code)
    assert_response :not_found
  end

  test "draw on waiting game rejected" do
    game = GameCreator.call
    sign_in_as_host(game)

    post game_draws_path(game.code)
    assert_response :redirect
    follow_redirect!
    assert flash[:alert].present?
  end

  test "consecutive draws increase position" do
    game = GameCreator.call
    game.update!(status: :active)
    sign_in_as_host(game)

    3.times do
      post game_draws_path(game.code)
    end

    draws = game.draws.order(:position)
    assert_equal [ 1, 2, 3 ], draws.pluck(:position)
    assert_equal 3, draws.pluck(:number).uniq.length
  end

  test "draw on game with 75 draws raises" do
    game = GameCreator.call
    game.update!(status: :active)
    sign_in_as_host(game)

    # Create 75 draws
    (1..75).each_with_index do |num, idx|
      game.draws.create!(number: num, position: idx + 1)
    end

    post game_draws_path(game.code)
    assert_response :redirect
    follow_redirect!
    assert flash[:alert].present?
  end
end
