require "application_system_test_case"

class GuestSecondDrawTest < ApplicationSystemTestCase
  test "guest sees the second draw update live" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5
    code = Game.order(:created_at).last.code

    Capybara.using_session(:guest) do
      visit game_path(code: code)
      assert_text "Aguardando o dono iniciar o jogo", wait: 5
    end

    click_button "Iniciar sorteio"
    assert_selector "button", text: "Sortear bola", wait: 5

    Capybara.using_session(:guest) do
      assert_text "0 / 75", wait: 5
    end

    click_button "Sortear bola"
    assert_text "1 / 75", wait: 5

    Capybara.using_session(:guest) do
      assert_text "1 / 75", wait: 5
    end

    click_button "Sortear bola"
    assert_text "2 / 75", wait: 5

    Capybara.using_session(:guest) do
      assert_text "2 / 75", wait: 8
    end
  end
end
