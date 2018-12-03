# frozen_string_literal: true

class CreateCommentLikes < ActiveRecord::Migration[5.2]
  def change
    create_table :comment_likes do |t|
      t.references :user
      t.references :comment
    end

    add_index :comment_likes, %i[user_id comment_id], unique: true
  end
end
