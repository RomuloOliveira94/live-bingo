# Picks the request's locale. Accept-Language is consulted FIRST: it's an
# explicit statement of the visitor's own preference, whereas the
# CF-IPCountry-derived guess is only a proxy inference (a Lusophone visitor
# outside Brazil — Portugal, Angola, Mozambique — sending `Accept-Language:
# pt` wants pt-BR, not the English a bare country lookup would hand them).
# Country only steps in once Accept-Language has nothing usable to say, and
# ultimately falls back to config.i18n.default_locale (pt-BR) when neither
# signal yields anything we recognize.
class LocaleResolver
  BRAZIL = "BR"
  LOCALE_BY_LANGUAGE = { "pt" => :"pt-BR", "en" => :en }.freeze

  def self.call(request) = new(request).call

  def initialize(request)
    @request = request
  end

  def call
    accept_language_locale || country_locale || I18n.default_locale
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
