# frozen_string_literal: true

class AddCommentToProposals < ActiveRecord::Migration[5.2]
  def change
    add_reference :proposals, :comment, foreign_key: true
  end
end
