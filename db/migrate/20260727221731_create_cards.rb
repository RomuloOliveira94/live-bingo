class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :game, null: false, foreign_key: true
      t.string :session_id, null: false
      t.json :grid_data, null: false

      t.timestamps
    end
    add_index :cards, [ :game_id, :session_id ], unique: true
  end
end
