require "application_system_test_case"

class GamesSystemTest < ApplicationSystemTestCase
  test "home renders 2 buttons" do
    visit root_path

    assert_selector "h1", text: "Bingo"
    assert_selector "a", text: "Criar bingo"
    assert_selector "a", text: "Entrar com código"
  end

  test "host creates game and sees waiting room" do
    visit root_path

    click_link "Criar bingo"

    # Should land on waiting room with the game code visible
    assert_selector "#game-code", wait: 5
    assert_selector "button", text: "Iniciar bingo"
    assert_text "Aguardando"
  end

  test "host draws number updates view" do
    # Host creates game
    visit root_path
    click_link "Criar bingo"

    assert_selector "button", text: "Iniciar bingo", wait: 5

    # Start the game
    click_button "Iniciar bingo"

    # Should now see active game UI
    assert_text "Em andamento"
    assert_selector "button", text: "Sortear número"

    # Draw a number
    click_button "Sortear número"

    # Should see a number in the ball (not the placeholder)
    within "#last-ball" do
      assert_no_text "—", wait: 5
    end
  end

  test "host restarts clears draws" do
    # Host creates game
    visit root_path
    click_link "Criar bingo"

    assert_selector "button", text: "Iniciar bingo", wait: 5

    # Start the game
    click_button "Iniciar bingo"

    # Draw a number
    click_button "Sortear número"

    # Wait for ball to appear
    within "#last-ball" do
      assert_no_text "—", wait: 5
    end

    # Accept the confirm dialog
    accept_confirm do
      click_button "Reiniciar"
    end

    # Ball should be back to placeholder
    within "#last-ball" do
      assert_text "—", wait: 5
    end
  end

  test "guest enters via code and sees waiting message" do
    # Create game directly
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    # Guest enters via code
    visit root_path
    click_link "Entrar com código"
    fill_in "Código do bingo", with: game.code
    click_button "Entrar"

    # Should see the game page
    assert_text "Aguardando o dono iniciar o jogo", wait: 5
  end
end
