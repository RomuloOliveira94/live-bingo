module ApplicationHelper
  def human_pattern(pattern)
    I18n.t("patterns.#{pattern}")
  end

  def human_game_status(status)
    I18n.t("statuses.game.#{status}")
  end

  def human_win_status(status)
    I18n.t("statuses.win.#{status}")
  end
end
