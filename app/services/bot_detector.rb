# Recognizes well-known crawlers/bots by their User-Agent string. Used by
# GameVisitTracker to keep bot traffic out of the game_visits analytics
# table — a link-preview crawler fetching a shared game page (see
# GamesController#show and robots.txt's comment in config/routes.rb for why
# that fetch is now allowed at all) isn't a real player, and counting it
# would pollute the very traffic data the owner wants to analyze.
#
# Deliberately a short, explicit pattern rather than a general-purpose "is
# this a bot" library — matching this app's existing dependency-free
# approach to user-agent handling (see UserAgentParser). "bot|crawler|
# spider" alone already covers the overwhelming majority of both search
# crawlers (Googlebot, bingbot, YandexBot, Baiduspider...) and the social
# link-preview crawlers this app cares about (Twitterbot, Slackbot,
# Discordbot, TelegramBot, LinkedInBot all end in "bot"); facebookexternalhit
# and WhatsApp are called out explicitly since neither name contains any of
# those three words.
class BotDetector
  PATTERN = /bot|crawler|spider|facebookexternalhit|whatsapp/i

  def self.call(user_agent) = user_agent.to_s.match?(PATTERN)
end
