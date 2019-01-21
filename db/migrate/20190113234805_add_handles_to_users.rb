# frozen_string_literal: true

class AddHandlesToUsers < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      t.string :username, null: true
      t.string :email, null: true, limit: 20
    end

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
