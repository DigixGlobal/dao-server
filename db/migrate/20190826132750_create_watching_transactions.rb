# frozen_string_literal: true

class CreateWatchingTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :watching_transactions, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :group_id, limit: 36, index: true, null: false
      t.string :transaction_object, null: false
      t.string :signed_transaction, null: false
      t.string :txhash
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_index :watching_transactions, :txhash, unique: true
  end
end
