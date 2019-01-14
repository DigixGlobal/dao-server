# frozen_string_literal: true

class CreateUserAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :user_audits do |t|
      t.integer :user_id, null: false
      t.string :event, null: false
      t.string :field, null: false
      t.string :old_value, null: false
      t.string :new_value, null: false
      t.timestamps
    end
  end
end
