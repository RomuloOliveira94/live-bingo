require "test_helper"

class GameTest < ActiveSupport::TestCase
  # Associations
  test "should have many draws" do
    game = games(:one)
    assert_respond_to game, :draws
  end

  # Enums
  test "should define status enum" do
    assert_equal %w[waiting active finished], Game.statuses.keys
  end

  test "status enum methods work" do
    game = games(:one)
    assert game.waiting?
    game.active!
    assert game.active?
  end

  # Validations
  test "should be valid with valid attributes" do
    game = Game.new(code: "TEST99", host_session_id: "session123", status: :waiting)
    assert game.valid?
  end

  test "should auto-generate code on create" do
    game = Game.new(host_session_id: "session123", status: :waiting)
    assert game.valid?
    assert_not_nil game.code
    assert_equal 6, game.code.length
  end

  test "should require unique code" do
    game1 = games(:one)
    game2 = Game.new(code: game1.code, host_session_id: "session123", status: :waiting)
    assert_not game2.valid?
    assert_includes game2.errors[:code], "já está em uso"
  end

  test "should require code length of 6" do
    game = Game.new(code: "ABC12", host_session_id: "session123", status: :waiting)
    assert_not game.valid?
    assert_includes game.errors[:code], "não possui o tamanho correto (deve ser 6 caracteres)"
  end

  test "should require code format" do
    game = Game.new(code: "abc123", host_session_id: "session123", status: :waiting)
    assert_not game.valid?
    assert game.errors[:code].any?
  end

  test "should require host_session_id" do
    game = Game.new(code: "ABC123", status: :waiting)
    assert_not game.valid?
    assert_includes game.errors[:host_session_id], "não pode ficar em branco"
  end

  test "should require status" do
    game = Game.new(code: "ABC123", host_session_id: "session123")
    game.status = nil
    assert_not game.valid?
  end

  # Callbacks
  test "should generate code on create" do
    game = Game.new(host_session_id: "session123", status: :waiting)
    assert game.save
    assert_not_nil game.code
    assert_equal 6, game.code.length
    assert_match(/\A[A-Z0-9]{6}\z/, game.code)
  end

  test "should not overwrite existing code" do
    game = Game.new(code: "CUSTOM", host_session_id: "session123", status: :waiting)
    assert game.save
    assert_equal "CUSTOM", game.code
  end

  test "generated code excludes ambiguous characters" do
    100.times do
      game = Game.new(host_session_id: "session123", status: :waiting)
      assert game.save
      assert_no_match(/[0O1IL]/, game.code)
    end
  end

  # viewer_count
  test "viewer_count defaults to 0" do
    game = Game.new(host_session_id: "session123", status: :waiting)
    assert game.save
    assert_equal 0, game.viewer_count
  end
end
