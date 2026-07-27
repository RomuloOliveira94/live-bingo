class SessionData
  COOKIE_NAME = :bingo_session
  EXPIRATION = 24.hours

  attr_reader :role, :game_id, :host_session_id, :guest_session_id

  def initialize(role:, game_id:, host_session_id: nil, guest_session_id: nil)
    @role = role
    @game_id = game_id
    @host_session_id = host_session_id
    @guest_session_id = guest_session_id
  end

  def self.cookies_to_session(cookies)
    raw = if Rails.env.test?
            cookies[COOKIE_NAME]
    elsif cookies.respond_to?(:signed)
            cookies.signed[COOKIE_NAME]
    else
            cookies[COOKIE_NAME]
    end
    return nil if raw.blank?

    data = JSON.parse(raw)
    new(
      role: data["role"],
      game_id: data["game_id"],
      host_session_id: data["host_session_id"],
      guest_session_id: data["guest_session_id"]
    )
  rescue JSON::ParserError
    nil
  end

  def self.host_for(game)
    new(
      role: "host",
      game_id: game.id,
      host_session_id: game.host_session_id
    )
  end

  def self.guest_for(game, session_id:)
    new(
      role: "guest",
      game_id: game.id,
      guest_session_id: session_id
    )
  end

  def write_to(cookies)
    if Rails.env.test?
      cookies[COOKIE_NAME] = to_h.to_json
    elsif cookies.respond_to?(:signed)
      cookies.signed[COOKIE_NAME] = {
        value: to_h.to_json,
        expires: EXPIRATION,
        httponly: true,
        same_site: :lax
      }
    else
      cookies[COOKIE_NAME] = to_h.to_json
    end
  end

  def to_h
    {
      role: role,
      game_id: game_id,
      host_session_id: host_session_id,
      guest_session_id: guest_session_id
    }.compact
  end
end
