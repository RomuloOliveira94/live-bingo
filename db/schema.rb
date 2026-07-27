# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_27_221734) do
  create_table "cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.json "grid_data", null: false
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "session_id"], name: "index_cards_on_game_id_and_session_id", unique: true
    t.index ["game_id"], name: "index_cards_on_game_id"
  end

  create_table "draws", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "number", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "number"], name: "index_draws_on_game_id_and_number", unique: true
    t.index ["game_id", "position"], name: "index_draws_on_game_id_and_position"
    t.index ["game_id"], name: "index_draws_on_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.string "host_session_id", null: false
    t.string "name"
    t.integer "pattern", default: 0, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_games_on_code", unique: true
    t.index ["host_session_id"], name: "index_games_on_host_session_id"
  end

  create_table "wins", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "pattern", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_wins_on_card_id"
    t.index ["game_id", "card_id", "pattern"], name: "index_wins_on_game_id_and_card_id_and_pattern", unique: true
    t.index ["game_id"], name: "index_wins_on_game_id"
  end

  add_foreign_key "cards", "games"
  add_foreign_key "draws", "games"
  add_foreign_key "wins", "cards"
  add_foreign_key "wins", "games"
end
