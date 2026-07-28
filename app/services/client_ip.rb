# Resolves the visitor's real IP behind Cloudflare.
#
# Cloudflare terminates the visitor's TCP connection and opens a new one to
# our origin, so `request.remote_ip` alone resolves to *Cloudflare's edge
# IP*, not the visitor's — Rails' RemoteIp middleware only looks past a proxy
# it trusts, and Cloudflare's edge isn't (and shouldn't be, without pinning
# to their published IP ranges) in `config.action_dispatch.trusted_proxies`.
# Cloudflare sends the real client IP explicitly in `CF-Connecting-IP` for
# exactly this reason, so that takes priority; `remote_ip` remains the
# fallback for local dev and any deploy not sitting behind Cloudflare.
#
# Spoofable like any client-supplied header if the origin isn't actually
# behind Cloudflare (or a request reaches it directly, bypassing Cloudflare)
# — acceptable here since this only feeds analytics/locale selection, never
# an authorization decision.
class ClientIp
  def self.call(request) = new(request).call

  def initialize(request)
    @request = request
  end

  def call
    @request.headers["CF-Connecting-IP"].presence || @request.remote_ip
  end
end
