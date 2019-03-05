# frozen_string_literal: true

class AddProjectDetailsToTransactions < ActiveRecord::Migration[5.2]
  def change
    change_table :transactions do |t|
      t.integer :transaction_type, null: true
      t.string :project, null: true
    end
  end
end
