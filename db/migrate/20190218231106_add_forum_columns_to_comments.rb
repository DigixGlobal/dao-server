# frozen_string_literal: true

class AddForumColumnsToComments < ActiveRecord::Migration[5.2]
  def change
    change_table :comments do |t|
      t.boolean :is_banned, null: false, default: false
    end
  end
end
