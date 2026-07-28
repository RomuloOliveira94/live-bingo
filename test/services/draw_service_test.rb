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
end
