class CreateNonces < ActiveRecord::Migration[5.2]
  def change
    create_table :nonces do |t|
      t.string :server
      t.integer :nonce
      t.timestamps
    end
  end
end
