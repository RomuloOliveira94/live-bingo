class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :code, null: false
      t.string :name
      t.string :host_session_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :pattern, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :games, :code, unique: true
    add_index :games, :host_session_id
  end
end
