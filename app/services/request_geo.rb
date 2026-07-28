# Geo lookup sourced entirely from Cloudflare's request headers — no
# MaxMind/external API. CF-Region and CF-IPCity only exist on Cloudflare
# Business/Enterprise plans; on the free plan (or when the app isn't behind
# Cloudflare at all) they're simply absent, and every value here degrades to
# nil rather than raising.
#
# Spoofable like any client-supplied header unless the origin only accepts
# traffic from Cloudflare — low-impact here since geo only drives analytics
# and locale selection, never authorization.
class RequestGeo
  # Cloudflare's own sentinel values for "no real country": XX means it
  # couldn't determine one, T1 means the request came through the Tor
  # network. Neither is a real country code.
  UNRESOLVED_COUNTRY_CODES = %w[XX T1].freeze

  def self.call(request) = new(request).call

  def initialize(request)
    @request = request
  end

  def call
    { country_code: country_code, region: header("CF-Region"), city: header("CF-IPCity") }
  end

  private

  def country_code
    code = header("CF-IPCountry")
    return nil if code.blank? || UNRESOLVED_COUNTRY_CODES.include?(code)

    code
  end

  def header(name)
    @request.headers[name].presence
  end
end
