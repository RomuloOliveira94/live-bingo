class DropWinsAndPattern < ActiveRecord::Migration[8.1]
  def change
    drop_table :wins, force: :cascade do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :pattern, null: false
      t.integer :status, null: false, default: 0
      t.datetime :confirmed_at
      t.timestamps
    end

    remove_column :games, :pattern, :integer, default: 0, null: false
    add_column :games, :viewer_count, :integer, default: 0, null: false
  end
end
