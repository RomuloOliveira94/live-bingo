# Small, dependency-free UA parser: good enough to bucket visits by
# browser/OS/device for usage analysis, without pulling in a gem. The raw
# `user_agent` string is stored alongside these derived fields (see
# GameVisitTracker), so anything this gets wrong — or misses entirely — can
# be re-derived later with a smarter parser.
class UserAgentParser
  # Order matters: checked top to bottom, first match wins. Chromium-based
  # browsers all carry "Chrome" (and often "Safari") in their UA string, so
  # their distinguishing tokens must be checked before the generic ones.
  BROWSER_PATTERNS = [
    [ /Edg\//, "Edge" ],
    [ /OPR\/|Opera/, "Opera" ],
    [ /SamsungBrowser/, "Samsung Internet" ],
    [ /Firefox/, "Firefox" ],
    [ /CriOS|Chrome/, "Chrome" ],
    [ /Safari/, "Safari" ]
  ].freeze

  # Same ordering concern: Android and Chrome OS UAs both also contain
  # "Linux", so they must be checked first.
  OS_PATTERNS = [
    [ /Windows NT/, "Windows" ],
    [ /iPhone|iPad|iPod/, "iOS" ],
    [ /Android/, "Android" ],
    [ /Mac OS X/, "macOS" ],
    [ /CrOS/, "Chrome OS" ],
    [ /Linux/, "Linux" ]
  ].freeze

  def self.call(user_agent) = new(user_agent).call

  def initialize(user_agent)
    @ua = user_agent.to_s
  end

  def call
    { browser: browser, os: os, device_type: device_type }
  end

  private

  def browser
    BROWSER_PATTERNS.find { |pattern, _| @ua.match?(pattern) }&.last || "Other"
  end

  def os
    OS_PATTERNS.find { |pattern, _| @ua.match?(pattern) }&.last || "Other"
  end

  def device_type
    return :unknown if @ua.blank?
    return :tablet if @ua.match?(/iPad|Tablet/) || (@ua.match?(/Android/) && !@ua.match?(/Mobile/))
    return :mobile if @ua.match?(/Mobi|iPhone|iPod|Android|BlackBerry|IEMobile|Opera Mini/)

    :desktop
  end
end
