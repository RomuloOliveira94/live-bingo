require "application_system_test_case"

class GamesSystemTest < ApplicationSystemTestCase
  test "host creates game from home" do
    visit root_path

    assert_selector "h1", text: "Bingo"
    assert_selector "form"

    fill_in "Nome do bingo (opcional)", with: "Bingo Teste"
    select "Linha", from: "Padrão de vitória"

    click_button "Criar bingo"

    # Should land on waiting room with the game code visible
    assert_selector "#game-code", wait: 5
    assert_selector "#host-controls"
    assert_text "Aguardando convidados"
  end

  test "guest joins game via link" do
    # Host creates a game first
    game = GameCreator.call(name: "Bingo Sistema")

    # Guest visits the game page (no cookie → visitor state)
    visit game_path(game.code)

    assert_text "Bingo Sistema"
    assert_selector "#game-status", text: "Aguardando"

    # Click join button
    click_button "Entrar no bingo"

    # Should see the card after joining
    assert_text "Sua cartela"
    assert_selector ".grid-cols-5", wait: 5
  end

  test "host draws number updates view" do
    # Host creates game
    visit root_path
    fill_in "Nome do bingo (opcional)", with: "Bingo Draw"
    click_button "Criar bingo"

    assert_selector "#host-controls", wait: 5

    # Start the game
    click_button "Começar bingo"

    # Should now see active game UI
    assert_text "Em andamento"
    assert_selector "button", text: "Sortear número"

    # Draw a number
    click_button "Sortear número"

    # Should see a number in the ball (not the placeholder)
    within ".w-28, .w-36" do
      assert_no_text "—", wait: 5
    end
  end
end
