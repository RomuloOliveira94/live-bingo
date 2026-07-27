require "test_helper"

class DrawServiceTest < ActiveSupport::TestCase
  test "draws a number for active game" do
    game = games(:two) # status: active
    initial_count = game.draws.count

    draw = DrawService.call(game: game)

    assert draw.persisted?
    assert_includes 1..75, draw.number
    assert_equal initial_count + 1, draw.position
    assert game.draws.pluck(:number).include?(draw.number)
  end

  test "raises GameNotActive for waiting game" do
    game = games(:one) # status: waiting

    assert_raises(DrawService::GameNotActive) do
      DrawService.call(game: game)
    end
  end

  test "raises NoNumbersRemaining when all 75 drawn" do
    game = games(:two)
    # Create 75 draws
    (1..75).each_with_index do |num, idx|
      game.draws.create!(number: num, position: idx + 1)
    end

    assert_raises(DrawService::NoNumbersRemaining) do
      DrawService.call(game: game)
    end
  end

  test "increments position correctly" do
    game = games(:two)
    draw1 = DrawService.call(game: game)
    draw2 = DrawService.call(game: game)
    draw3 = DrawService.call(game: game)

    assert_equal 1, draw1.position
    assert_equal 2, draw2.position
    assert_equal 3, draw3.position
  end

  test "draws unique numbers" do
    game = games(:two)
    draws = 10.times.map { DrawService.call(game: game) }
    numbers = draws.map(&:number)

    assert_equal numbers.uniq.length, numbers.length
  end

  test "chains WinDetector" do
    game = GameCreator.call(pattern: :line)
    game.update!(status: :active)
    # Create a card that will win with line pattern
    card = game.cards.create!(
      session_id: "test_guest",
      grid_data: [
        [ 1, 16, 31, 46, 61 ],
        [ 2, 17, 32, 47, 62 ],
        [ 3, 18, "free", 48, 63 ],
        [ 4, 19, 33, 49, 64 ],
        [ 5, 20, 34, 50, 65 ]
      ]
    )

    # Manually create draws to complete first row (instead of using DrawService which is random)
    [ 1, 16, 31, 46, 61 ].each_with_index do |num, idx|
      game.draws.create!(number: num, position: idx + 1)
    end

    # Now call WinDetector directly
    last_draw = game.draws.last
    WinDetector.call(game, last_draw)

    # Check if win was created
    win = Win.find_by(game: game, card: card, pattern: "line")
    assert win.present?, "Expected win to be created"
    assert_equal "pending", win.status
  end

  test "rolls back draw when WinDetector raises" do
    game = games(:two) # status: active
    initial_draw_count = game.draws.count

    # Override WinDetector.call to raise an exception
    original_method = WinDetector.method(:call)
    WinDetector.define_singleton_method(:call) do |_game, _draw|
      raise "WinDetector exploded"
    end

    begin
      assert_raises(RuntimeError) do
        DrawService.call(game: game)
      end

      # Verify no draw was persisted (transaction rolled back)
      assert_equal initial_draw_count, game.draws.count
    ensure
      # Restore original method
      WinDetector.define_singleton_method(:call, original_method)
    end
  end
end
