class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_session

  around_action :set_locale
  before_action :load_current_session
  after_action :vary_by_accept_language

  private

  # Every page renders differently depending on Accept-Language (see
  # LocaleResolver) at a single URL, with no locale-prefixed routes — so any
  # cache sitting in front of this app (a browser's own cache, a CDN) must
  # key on that header too, or it'll serve one visitor's resolved locale to
  # the next. Complements the hreflang self-references in
  # layouts/_seo_head.html.erb, which document the same single-URL,
  # content-negotiated approach to Google.
  def vary_by_accept_language
    response.headers["Vary"] = "Accept-Language"
  end

  # Wraps the whole request (rather than assigning I18n.locale directly) so
  # it can never leak into the next request handled by the same Puma thread
  # — I18n.locale is thread-local, not request-local, and threads are reused
  # across requests.
  def set_locale
    I18n.with_locale(resolved_locale) { yield }
  end

  def resolved_locale
    @resolved_locale ||= LocaleResolver.call(request)
  end

  def load_current_session
    Current.session = SessionData.ensure_session(cookies)
  end

  def set_session_cookie(session_data)
    session_data.write_to(cookies)
  end

  def current_session
    Current.session
  end
end
