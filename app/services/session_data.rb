class SessionData
  COOKIE_NAME = :bingo_session
  EXPIRATION = 30.days
  HOST_ID_BYTES = 16

  attr_reader :host_id

  def initialize(host_id:)
    @host_id = host_id
  end

  def self.host_id_for_new_game
    SecureRandom.hex(HOST_ID_BYTES)
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
    new(host_id: data["host_id"])
  rescue JSON::ParserError
    nil
  end

  def self.write_new(cookies)
    new(host_id: host_id_for_new_game).tap { |s| s.write_to(cookies) }
  end

  def write_to(cookies)
    payload = { host_id: host_id }.to_json
    if Rails.env.test?
      cookies[COOKIE_NAME] = payload
    elsif cookies.respond_to?(:signed)
      cookies.signed[COOKIE_NAME] = {
        value: payload,
        expires: EXPIRATION,
        httponly: true,
        same_site: :lax
      }
    else
      cookies[COOKIE_NAME] = payload
    end
  end

  def host_of?(game)
    host_id.present? && game.host_session_id == host_id
  end
end
