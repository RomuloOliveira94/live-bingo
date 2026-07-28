# Records one analytics row per visitor per game (see GameVisit / migration
# for the "why" of the shape). Called on the hot path of every game
# create/view, so this must cost exactly one INSERT and never raise into the
# request — a tracking failure is a logged non-event, not a broken page.
#
# Dedup ("evitar duplicação") is enforced by the DB's unique index on
# [visitor_token, game_id], not by a SELECT-then-insert check: insert_all's
# `unique_by` compiles to a single `INSERT ... ON CONFLICT DO NOTHING`, so a
# returning visitor — or two concurrent requests racing each other — costs
# the same one round-trip and never raises RecordNotUnique.
class GameVisitTracker
  def self.call(game:, request:, visitor_token:, kind:) = new(game, request, visitor_token, kind).call

  def initialize(game, request, visitor_token, kind)
    @game = game
    @request = request
    @visitor_token = visitor_token
    @kind = kind
  end

  def call
    return if @visitor_token.blank?

    GameVisit.insert_all([ attributes ], unique_by: %i[visitor_token game_id])
  rescue StandardError => e
    Rails.logger.error("[GameVisitTracker] failed to record visit for game #{@game&.id}: #{e.class}: #{e.message}")
    nil
  end

  private

  def attributes
    ua = UserAgentParser.call(@request.user_agent)
    geo = RequestGeo.call(@request)
    now = Time.current

    {
      game_id: @game.id,
      visitor_token: @visitor_token,
      kind: GameVisit.kinds.fetch(@kind.to_s),
      ip_address: AnonymizedIp.call(ClientIp.call(@request)),
      user_agent: @request.user_agent.to_s.truncate(500),
      browser: ua[:browser],
      os: ua[:os],
      device_type: GameVisit.device_types.fetch(ua[:device_type].to_s),
      country_code: geo[:country_code],
      region: geo[:region],
      city: geo[:city],
      locale: I18n.locale.to_s,
      created_at: now,
      updated_at: now
    }
  end
end
