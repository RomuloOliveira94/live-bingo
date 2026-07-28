# Crawler-facing endpoints: robots.txt and sitemap.xml. Deliberately does
# NOT inherit from ApplicationController — this content isn't
# locale-dependent (see LocaleResolver) and a bot fetching it shouldn't mint
# a bingo_session cookie or otherwise be treated like a regular page view
# (see ApplicationController#load_current_session).
class SeoController < ActionController::Base
  def robots
    render layout: false
  end

  def sitemap
    render layout: false
  end
end
