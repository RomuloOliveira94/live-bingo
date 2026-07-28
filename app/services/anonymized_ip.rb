require "ipaddr"

# Anonymizes a visitor's IP for storage: zero the last octet for IPv4
# (189.45.32.77 -> 189.45.32.0), truncate to the /64 network prefix for
# IPv6. Never stores (or returns) the raw address.
class AnonymizedIp
  IPV4_MASK_BITS = 24
  IPV6_MASK_BITS = 64

  def self.call(raw_ip) = new(raw_ip).call

  def initialize(raw_ip)
    @raw_ip = raw_ip
  end

  def call
    return nil if @raw_ip.blank?

    addr = IPAddr.new(@raw_ip)
    addr.ipv4? ? addr.mask(IPV4_MASK_BITS).to_s : addr.mask(IPV6_MASK_BITS).to_s
  rescue IPAddr::Error
    nil
  end
end
