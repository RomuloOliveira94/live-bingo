require "test_helper"

# Verifies pt-BR (primary) and en (secondary) never drift apart: every key
# translated in one locale must exist in the other.
class I18nLocaleParityTest < ActiveSupport::TestCase
  # `activerecord.attributes.*` (human-readable attribute names like "Número")
  # is pt-BR-only by design: Rails auto-humanizes attribute names in English
  # (:host_session_id => "Host session"), so there's nothing to mirror in
  # en.yml. `activerecord.errors.*` is NOT excluded (unlike an earlier version
  # of this comment claimed) — those messages are checked for parity like
  # everything else, and en.yml declares plain-English equivalents for them.
  #
  # Known limitation: parity only catches a key declared in one locale file
  # but missing from the other. It can't catch a key missing from BOTH files,
  # which is exactly the shape of bug that let Draw's `numericality: { in: }`
  # validator silently render its English gem default in pt-BR for a while —
  # neither locale file had `errors.messages.in` at all, so there was no
  # asymmetry to flag. That class of gap is guarded by model tests asserting
  # exact translated message content instead (see test/models/draw_test.rb).
  EXCLUDED_NAMESPACES = %w[activerecord.attributes].freeze

  test "pt-BR and en declare the same set of keys" do
    pt_br_keys = locale_keys("pt-BR")
    en_keys = locale_keys("en")

    missing_in_en = pt_br_keys - en_keys
    missing_in_pt_br = en_keys - pt_br_keys

    assert_empty missing_in_en, "Keys present in pt-BR.yml but missing from en.yml: #{missing_in_en.join(', ')}"
    assert_empty missing_in_pt_br, "Keys present in en.yml but missing from pt-BR.yml: #{missing_in_pt_br.join(', ')}"
  end

  private

  def locale_keys(locale)
    data = YAML.load_file(Rails.root.join("config/locales/#{locale}.yml"))[locale]
    flatten_keys(data).reject { |key| excluded?(key) }.sort
  end

  def excluded?(key)
    EXCLUDED_NAMESPACES.any? { |namespace| key == namespace || key.start_with?("#{namespace}.") }
  end

  def flatten_keys(hash, prefix = nil)
    hash.each_with_object([]) do |(key, value), keys|
      full_key = prefix ? "#{prefix}.#{key}" : key.to_s
      if value.is_a?(Hash)
        keys.concat(flatten_keys(value, full_key))
      else
        keys << full_key
      end
    end
  end
end
