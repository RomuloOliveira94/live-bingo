class WinConfirmer
  def self.call(win:, action: :confirm) = new(win: win, action: action).call

  def initialize(win:, action: :confirm)
    @win = win
    @action = action
  end

  def call
    case @action.to_sym
    when :confirm
      @win.update!(status: :confirmed, confirmed_at: Time.current)

      if @win.game.pattern == "blackout" && @win.pattern == "blackout"
        @win.game.update!(status: :finished, finished_at: Time.current)
      end
    when :cancel
      @win.update!(status: :cancelled)
    end

    @win
  end
end
