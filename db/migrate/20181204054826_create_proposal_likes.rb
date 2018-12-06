# frozen_string_literal: true

class CreateProposalLikes < ActiveRecord::Migration[5.2]
  def change
    create_table :proposal_likes do |t|
      t.references :user
      t.references :proposal
    end

    add_index :proposal_likes, %i[user_id proposal_id], unique: true
  end
end
