class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_session

  before_action :load_current_session

  private

  def load_current_session
    Current.session = SessionData.cookies_to_session(cookies)
  end

  def set_session_cookie(session_data)
    session_data.write_to(cookies)
  end

  def current_session
    Current.session
  end
end
