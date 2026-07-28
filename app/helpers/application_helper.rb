module ApplicationHelper
  def human_game_status(status)
    I18n.t("statuses.game.#{status}")
  end

  def format_game_code(code)
    return "" if code.blank?
    code.to_s.scan(/.{1,3}/).first(2).join("-")
  end

  def game_url_for_sharing(game)
    "#{request.base_url}#{game_path(code: game.code)}"
  end

  def is_host_of?(game)
    Current.host_of?(game)
  end
end
