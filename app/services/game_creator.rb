class GameCreator
  class Error < StandardError; end

  def self.call(name: nil, pattern: :line) = new(name: name, pattern: pattern).call

  def initialize(name: nil, pattern: :line)
    @name = name
    @pattern = pattern
  end

  def call
    Game.create!(
      name: @name,
      pattern: @pattern,
      status: :waiting,
      host_session_id: SecureRandom.hex(16)
    )
  end
end
