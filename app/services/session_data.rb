class SessionData
  COOKIE_NAME = :bingo_session
  EXPIRATION = 30.days
  HOST_ID_BYTES = 16
  VISITOR_TOKEN_BYTES = 16

  attr_reader :host_id, :visitor_token

  def initialize(host_id:, visitor_token: nil)
    @host_id = host_id
    @visitor_token = visitor_token
  end

  def self.host_id_for_new_game
    SecureRandom.hex(HOST_ID_BYTES)
  end

  def self.new_visitor_token
    SecureRandom.hex(VISITOR_TOKEN_BYTES)
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
    new(host_id: data["host_id"], visitor_token: data["visitor_token"])
  rescue JSON::ParserError
    nil
  end

  # Every request needs a stable per-browser visitor_token — host and guest
  # alike — for analytics, so this is called from every request (see
  # ApplicationController#load_current_session), not just game creation.
  # Mints one on first contact and preserves whatever host_id (if any)
  # already round-tripped through the cookie; only writes back to `cookies`
  # when a token was actually missing, so a returning visitor costs no extra
  # write.
  def self.ensure_session(cookies)
    session = cookies_to_session(cookies)
    return session if session&.visitor_token.present?

    new(host_id: session&.host_id, visitor_token: new_visitor_token).tap { |s| s.write_to(cookies) }
  end

  def self.write_new(cookies)
    visitor_token = cookies_to_session(cookies)&.visitor_token || new_visitor_token
    new(host_id: host_id_for_new_game, visitor_token: visitor_token).tap { |s| s.write_to(cookies) }
  end

  def write_to(cookies)
    payload = { host_id: host_id, visitor_token: visitor_token }.to_json
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
