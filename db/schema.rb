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

ActiveRecord::Schema[8.1].define(version: 2026_07_28_020000) do
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

  create_table "game_visits", force: :cascade do |t|
    t.string "browser"
    t.string "city"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.integer "device_type", default: 3, null: false
    t.integer "game_id", null: false
    t.string "ip_address"
    t.integer "kind", default: 0, null: false
    t.string "locale"
    t.string "os"
    t.string "region"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.string "visitor_token", null: false
    t.index ["country_code"], name: "index_game_visits_on_country_code"
    t.index ["created_at"], name: "index_game_visits_on_created_at"
    t.index ["game_id"], name: "index_game_visits_on_game_id"
    t.index ["visitor_token", "game_id"], name: "index_game_visits_on_visitor_token_and_game_id", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.string "host_session_id", null: false
    t.string "name"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "viewer_count", default: 0, null: false
    t.index ["code"], name: "index_games_on_code", unique: true
    t.index ["host_session_id"], name: "index_games_on_host_session_id"
  end

  add_foreign_key "draws", "games"
  add_foreign_key "game_visits", "games"
end
