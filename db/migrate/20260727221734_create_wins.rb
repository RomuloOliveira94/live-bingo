class CreateWins < ActiveRecord::Migration[8.1]
  def change
    create_table :wins do |t|
      t.references :game, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :pattern, null: false
      t.integer :status, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps
    end
    add_index :wins, [ :game_id, :card_id, :pattern ], unique: true
  end
end
