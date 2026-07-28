# Picks the request's locale. Precedence, in order:
#
#   1. Accept-Language's primary language is Portuguese (any region: pt-BR,
#      pt-PT, bare "pt"...) -> pt-BR. An explicit statement of the visitor's
#      own preference beats everything else, and it's also how a Lusophone
#      visitor outside Brazil (Portugal, Angola, Mozambique) sending
#      `Accept-Language: pt` ends up with Portuguese instead of the English
#      a bare country lookup would hand them.
#   2. Otherwise, CF-IPCountry is BR -> pt-BR. A Brazilian visitor whose
#      browser/OS happens to be set to English (very common — most people
#      never touch that setting) still gets the Portuguese the product is
#      actually for, rather than English.
#   3. Otherwise, a country is present (and, per step 2, isn't BR) -> en.
#   4. Otherwise (no country signal at all — local dev, or any deployment
#      not sitting behind Cloudflare) -> config.i18n.default_locale (pt-BR).
#
# Deliberate consequence of step 4: an English-speaking visitor hitting a
# deployment with no Cloudflare in front of it gets pt-BR, not English, since
# there's no country signal to tell them apart from a Brazilian on the same
# non-Cloudflare deploy. That's an accepted trade-off, not a bug — the app is
# Brazilian-first, pt-BR is default_locale, and the one deployment that
# matters (production) sits behind Cloudflare, where step 3 applies. Do not
# "fix" this by making an unrecognized/absent country default to :en.
class LocaleResolver
  BRAZIL = "BR"
  PORTUGUESE = "pt"

  def self.call(request) = new(request).call

  def initialize(request)
    @request = request
  end

  def call
    return :"pt-BR" if portuguese_accept_language?
    return :"pt-BR" if country_code == BRAZIL
    return :en if country_code.present?

    I18n.default_locale
  end

  private

  def country_code
    @country_code ||= RequestGeo.call(@request)[:country_code]
  end

  def portuguese_accept_language?
    primary_language == PORTUGUESE
  end

  # Deliberately simple: takes the browser's most-preferred language tag
  # (the first one listed) rather than fully weighing every "q=" value —
  # browsers list their top preference first, so this covers the vast
  # majority of real requests without the parsing complexity.
  def primary_language
    header = @request.headers["Accept-Language"]
    return nil if header.blank?

    primary_tag = header.split(",").first.to_s.split(";").first.to_s.strip
    primary_tag.split("-").first&.downcase
  end
end
