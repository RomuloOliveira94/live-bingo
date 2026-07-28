require "application_system_test_case"

class GamesSystemTest < ApplicationSystemTestCase
  test "home renders 2 buttons" do
    visit root_path

    assert_selector "h1", text: /Crie uma sala de bingo/i, normalize_ws: true
    assert_selector "button", text: "Criar bingo"
    assert_selector "a", text: "Entrar com código"
  end

  test "host creates game and sees waiting room" do
    visit root_path

    click_button "Criar bingo"

    # Should land on waiting room with the game code visible
    assert_selector "#game-code", wait: 5
    assert_selector "button", text: "Iniciar sorteio"
    assert_text(/sala criada/i)
    assert_text "Chame a galera"
  end

  test "host draws number updates view" do
    # Host creates game
    visit root_path
    click_button "Criar bingo"

    assert_selector "button", text: "Iniciar sorteio", wait: 5

    # Start the game
    click_button "Iniciar sorteio"

    # Should now see active game UI
    assert_text(/ao vivo/i)
    assert_selector "button", text: "Sortear bola"

    # Draw a number
    click_button "Sortear bola"

    # Should see a number in the ball (not the placeholder)
    within "#last-ball" do
      assert_no_text "—", wait: 5
    end
  end

  test "host restarts clears draws" do
    # Host creates game
    visit root_path
    click_button "Criar bingo"

    assert_selector "button", text: "Iniciar sorteio", wait: 5

    # Start the game
    click_button "Iniciar sorteio"

    # Draw a number
    click_button "Sortear bola"

    # Wait for ball to appear
    within "#last-ball" do
      assert_no_text "—", wait: 5
    end

    # Accept the confirm dialog
    accept_confirm do
      click_button "Reiniciar partida"
    end

    # Ball should be back to its idle state (no number shown)
    within "#last-ball" do
      assert_no_text(/\d/, wait: 5)
    end
  end

  test "guest enters via code and sees waiting message" do
    # Create game directly
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    # Guest enters via code
    visit root_path
    click_link "Entrar com código"
    fill_in "Código do bingo", with: game.code
    click_button "Entrar na sala"

    # Should see the game page
    assert_text "Aguardando início do bingo", wait: 5
  end
end
