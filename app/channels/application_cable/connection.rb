module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :session

    def connect
      self.session = SessionData.cookies_to_session(cookies)
    end
  end
end
