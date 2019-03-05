# frozen_string_literal: true

class AddForumColumnsToUsers < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      t.boolean :is_banned, null: false, default: false
    end
  end
end
