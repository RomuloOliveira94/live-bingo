require "test_helper"

# Guards against hardcoded, non-translated user-facing copy creeping back
# into the views. Pragmatic regex-based scan, not a full ERB/HTML parser —
# it's meant to catch obvious literal prose, not every edge case.
class I18nHardcodedStringsTest < ActiveSupport::TestCase
  # PWA manifest is a JSON data file, not HTML prose — most of its string
  # values are technical (MIME types, sizes, "standalone", "ltr"...), so it's
  # exempt from the HTML text-node scan below. It's checked separately.
  VIEW_FILES = Dir.glob(Rails.root.join("app/views/**/*.erb")).reject { |f| f.end_with?(".json.erb") }.freeze

  # Matches one HTML tag, treating `>` inside quoted attribute values (e.g.
  # Stimulus's `turbo:submit-start->controller#action`) as non-terminating.
  HTML_TAG = /<(?:[^<>"']|"[^"]*"|'[^']*')*>/m

  # Text left over after stripping ERB tags and HTML tags that is fine to
  # leave as literal markup: blank lines and pure punctuation/glue used for
  # layout (dots, slashes, dashes) rather than words.
  ALLOWED_TEXT_NODE = /\A[\s\-·•\/|,.:()%]*\z/

  # Attributes that commonly carry user-facing copy. Flag them when their
  # value is a plain string literal instead of going through `t(...)`.
  TRANSLATABLE_ATTRS = %w[placeholder alt title aria_label aria-label turbo_confirm turbo_submits_with].freeze

  test "views contain no hardcoded text nodes" do
    offenders = VIEW_FILES.each_with_object({}) do |file, memo|
      content = File.read(file)
      without_erb = content.gsub(/<%.*?%>/m, "")
      # Strip <style>/<script> block contents wholesale — CSS/JS isn't prose.
      without_assets = without_erb.gsub(%r{<(style|script)\b[^>]*>.*?</\1>}mi, "")
      text_only = without_assets.gsub(HTML_TAG, "\n")

      leftover = text_only.lines.map(&:strip).reject { |line| line.match?(ALLOWED_TEXT_NODE) }
      memo[file] = leftover if leftover.any?
    end

    assert_empty offenders,
      "Hardcoded text nodes found in views (wrap them in t(...)):\n" +
      offenders.map { |file, lines| "  #{file.sub(Rails.root.to_s + '/', '')}: #{lines.join(' | ')}" }.join("\n")
  end

  test "translatable attributes are never hardcoded string literals" do
    offenders = VIEW_FILES.each_with_object({}) do |file, memo|
      content = File.read(file)
      bad = TRANSLATABLE_ATTRS.flat_map do |attr|
        # Matches both HTML `attr="value"` and Ruby option `attr: "value"` /
        # `attr: 'value'` syntax, capturing the literal value.
        content.scan(/#{Regexp.escape(attr)}[:=]\s*["']([^"']*)["']/).flatten
      end.select { |value| value.match?(/[a-zA-Z]/) }

      memo[file] = bad if bad.any?
    end

    assert_empty offenders,
      "Hardcoded translatable attribute values found (use t(...) instead):\n" +
      offenders.map { |file, values| "  #{file.sub(Rails.root.to_s + '/', '')}: #{values.join(', ')}" }.join("\n")
  end
end
