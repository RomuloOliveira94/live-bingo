module SessionHelpers
  def sign_in_as_host(game)
    cookies[:bingo_session] = { host_id: game.host_session_id }.to_json
  end

  def sign_in_as_viewer(host_id: nil)
    cookies[:bingo_session] = { host_id: host_id || SecureRandom.hex(16) }.to_json
  end

  def sign_out
    cookies.delete(:bingo_session)
  end
end
