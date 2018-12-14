# frozen_string_literal: true

class CreateProposals < ActiveRecord::Migration[5.2]
  def change
    create_table :proposals do |t|
      t.string :proposal_id, null: false, default: ''
      t.references :user, foreign_key: true
      t.integer :stage, default: 1
      t.integer :likes, default: 0
      t.timestamps
    end

    add_index :proposals, :stage
    add_index :proposals, :proposal_id, unique: true
  end
end
