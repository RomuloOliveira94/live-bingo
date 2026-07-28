# Picks the request's locale: Brazil gets pt-BR (unchanged default
# experience), everywhere else gets en. Falls back to the browser's
# Accept-Language header when Cloudflare's country header is missing or
# unusable (no Cloudflare in front, local dev, CF-IPCountry is XX/T1), and
# ultimately to config.i18n.default_locale (pt-BR) when even that yields
# nothing we recognize.
class LocaleResolver
  BRAZIL = "BR"
  LOCALE_BY_LANGUAGE = { "pt" => :"pt-BR", "en" => :en }.freeze

  def self.call(request) = new(request).call

  def initialize(request)
    @request = request
  end

  def call
    country_locale || accept_language_locale || I18n.default_locale
  end

  private

  def country_locale
    code = RequestGeo.call(@request)[:country_code]
    return nil if code.blank?

    code == BRAZIL ? :"pt-BR" : :en
  end

  # Deliberately simple: takes the browser's most-preferred language tag
  # (the first one listed) rather than fully weighing every "q=" value —
  # browsers list their top preference first, so this covers the vast
  # majority of real requests without the parsing complexity.
  def accept_language_locale
    header = @request.headers["Accept-Language"]
    return nil if header.blank?

    primary_tag = header.split(",").first.to_s.split(";").first.to_s.strip
    language = primary_tag.split("-").first&.downcase

    LOCALE_BY_LANGUAGE[language]
  end
end
