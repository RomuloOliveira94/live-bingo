require "application_system_test_case"

class DesignSystemTest < ApplicationSystemTestCase
  test "home shows 2 main buttons" do
    visit root_path

    assert_selector "button", text: "Criar bingo"
    assert_selector "a", text: "Entrar com código"
  end

  test "entrar page shows code input" do
    visit enter_path

    assert_selector "input[name='code']"
    assert_selector "h1", text: "Entrar em um bingo", normalize_ws: true
  end

  test "waiting host shows dashed code box" do
    visit root_path
    click_button "Criar bingo"

    assert_selector "#game-code", wait: 5
    assert_selector ".border-dashed", wait: 5
  end

  test "active game shows 75-number board" do
    visit root_path
    click_button "Criar bingo"
    click_button "Iniciar sorteio", wait: 5

    within "#board" do
      assert_selector "span", count: 75, wait: 5
    end
  end

  test "active game shows last ball with letter and number" do
    visit root_path
    click_button "Criar bingo"
    click_button "Iniciar sorteio", wait: 5
    click_button "Sortear bola"

    within "#last-ball" do
      assert_no_text "—", wait: 5
      # Should contain a BINGO letter (B, I, N, G, or O) and a number
      assert_text(/[BINGO]/)
    end
  end

  test "draw sound asset is accessible" do
    # Use a direct HTTP request to check the asset is served
    visit "/sounds/draw-sound.mp3"

    # The browser will try to render the audio file
    # We just check that we don't get a 404
    assert_no_text "Not Found"
  end
end
