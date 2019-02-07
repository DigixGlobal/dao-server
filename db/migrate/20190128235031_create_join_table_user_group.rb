# frozen_string_literal: true

class CreateJoinTableUserGroup < ActiveRecord::Migration[5.2]
  def change
    create_join_table :users, :groups do |t|
      t.index %i[user_id group_id], unique: true
    end
  end
end
