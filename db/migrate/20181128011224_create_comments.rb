# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.string :comment
      t.references :user, foreign_key: true
      t.references :proposal, foreign_key: true
      t.integer :parent_id
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :comments, :discarded_at
  end
end
