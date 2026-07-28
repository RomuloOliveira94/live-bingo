class CreateGameVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :game_visits do |t|
      t.references :game, null: false, foreign_key: true
      t.string :visitor_token, null: false
      t.integer :kind, null: false, default: 0
      t.string :ip_address
      t.text :user_agent
      t.string :browser
      t.string :os
      t.integer :device_type, null: false, default: 3
      # region/city are only populated on Cloudflare Business/Enterprise
      # plans (CF-Region / CF-IPCity headers) — nullable so a plan upgrade
      # needs no migration.
      t.string :country_code
      t.string :region
      t.string :city
      t.string :locale

      t.timestamps
    end

    # Enforces "one row per visitor per game" at the DB level so concurrent
    # requests (host's create immediately followed by their own show, two
    # browser tabs, a double-click) can't race past an app-level check.
    add_index :game_visits, [ :visitor_token, :game_id ], unique: true
    add_index :game_visits, :country_code
    add_index :game_visits, :created_at
  end
end
