require "application_system_test_case"

class RealtimeSystemTest < ApplicationSystemTestCase
  test "host starts game and sees active status" do
    visit root_path
    click_link "Criar bingo"

    assert_selector "#game-code", wait: 5
    assert_text "Aguardando"

    click_button "Iniciar bingo"

    assert_text "Em andamento"
    assert_selector "button", text: "Sortear número"
  end

  test "viewer sees waiting message" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    visit game_path(code: game.code)

    assert_text "Aguardando o dono iniciar o jogo"
  end
end
