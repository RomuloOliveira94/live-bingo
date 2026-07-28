require "application_system_test_case"

class ViewerCountLiveTest < ApplicationSystemTestCase
  test "host sees viewer count rise as guests join" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5
    code = Game.order(:created_at).last.code

    assert_text(/1\s*jogador na sala/, wait: 5)

    Capybara.using_session(:guest_one) do
      visit game_path(code: code)
      assert_text "Aguardando o dono iniciar o jogo", wait: 5
    end

    # Guest joined: host should now see 2
    assert_text(/2\s*jogadores na sala/, wait: 8)
  end
end
