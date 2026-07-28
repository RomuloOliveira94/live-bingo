require "application_system_test_case"

class RealtimeSystemTest < ApplicationSystemTestCase
  test "host starts game and sees active status" do
    visit root_path
    click_button "Criar bingo"

    assert_selector "#game-code", wait: 5
    assert_text "Chame a galera"

    click_button "Iniciar sorteio"

    assert_text(/ao vivo/i)
    assert_selector "button", text: "Sortear bola"
  end

  test "viewer sees waiting message" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)

    visit game_path(code: game.code)

    assert_text "Aguardando início do bingo"
  end
end
