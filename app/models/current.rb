class Current < ActiveSupport::CurrentAttributes
  attribute :session

  def host_of?(game)
    session&.host_of?(game)
  end
end
