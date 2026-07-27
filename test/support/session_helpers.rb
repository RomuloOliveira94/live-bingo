module SessionHelpers
  def sign_in_as_host(game)
    data = SessionData.host_for(game)
    cookies[:bingo_session] = data.to_h.to_json
  end

  def sign_in_as_guest(game, session_id: "guest_#{SecureRandom.hex(4)}")
    data = SessionData.guest_for(game, session_id: session_id)
    cookies[:bingo_session] = data.to_h.to_json
    data
  end

  def sign_out
    cookies.delete(:bingo_session)
  end
end
