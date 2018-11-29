# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.text :body, limit: 10_000
      t.integer :stage, default: 1
      t.references :user, foreign_key: true
      t.references :proposal, foreign_key: true
      t.integer :parent_id
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :comments, :discarded_at
    add_index :comments, %i[proposal_id stage]
  end
end
