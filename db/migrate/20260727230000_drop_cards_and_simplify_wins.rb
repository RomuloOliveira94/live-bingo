class DropCardsAndSimplifyWins < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :wins, :cards if foreign_key_exists?(:wins, :cards)
    remove_index :wins, [ :game_id, :card_id, :pattern ] if index_exists?(:wins, [ :game_id, :card_id, :pattern ])
    remove_column :wins, :card_id, :bigint if column_exists?(:wins, :card_id)

    drop_table :cards do |t|
      t.references :game, null: false, foreign_key: true
      t.string :session_id, null: false
      t.json :grid_data, null: false
      t.timestamps
    end
  end
end
