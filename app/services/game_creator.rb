class GameCreator
  def self.call(host_id:) = new(host_id).call

  def initialize(host_id)
    @host_id = host_id
  end

  def call
    Game.create!(host_session_id: @host_id, status: :waiting)
  end
end
