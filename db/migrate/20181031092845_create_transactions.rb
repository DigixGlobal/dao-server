# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.string :title
      t.string :txhash
      t.string :status, default: 'pending'
      t.integer :block_number
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_index :transactions, :txhash, unique: true
  end
end
