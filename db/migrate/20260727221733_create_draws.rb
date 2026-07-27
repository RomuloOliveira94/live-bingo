class CreateDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :draws do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :position, null: false

      t.timestamps
    end
    add_index :draws, [ :game_id, :number ], unique: true
    add_index :draws, [ :game_id, :position ]
  end
end
