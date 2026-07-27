class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :role, :game_id, :host_session_id, :guest_session_id, to: :session, allow_nil: true

  def host?
    role == "host"
  end

  def guest?
    role == "guest"
  end

  def host_of?(game)
    host? && game_id == game.id && host_session_id == game.host_session_id
  end
end
