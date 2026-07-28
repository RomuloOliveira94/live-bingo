require "test_helper"

class BotDetectorTest < ActiveSupport::TestCase
  # The exact link-preview crawlers named in the bugfix brief for "no
  # preview when sharing a game link on WhatsApp" (see GameVisitTracker and
  # config/routes.rb's robots.txt comment).
  test "recognizes the social/link-preview crawlers this app cares about" do
    [
      "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
      "WhatsApp/2.23.20.0",
      "Twitterbot/1.0",
      "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
      "Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)",
      "TelegramBot (like TwitterBot)",
      "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)"
    ].each do |ua|
      assert BotDetector.call(ua), "expected #{ua.inspect} to be recognized as a bot"
    end
  end

  test "recognizes common search engine crawlers" do
    [
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
      "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)",
      "Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)"
    ].each do |ua|
      assert BotDetector.call(ua), "expected #{ua.inspect} to be recognized as a bot"
    end
  end

  test "does not flag real browsers" do
    [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
    ].each do |ua|
      assert_not BotDetector.call(ua), "did not expect #{ua.inspect} to be recognized as a bot"
    end
  end

  test "handles blank/nil user agents without raising" do
    assert_not BotDetector.call(nil)
    assert_not BotDetector.call("")
  end
end
