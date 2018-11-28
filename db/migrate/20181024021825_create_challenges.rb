# frozen_string_literal: true

class CreateChallenges < ActiveRecord::Migration[5.2]
  def change
    create_table :challenges do |t|
      t.string :challenge
      t.boolean :proven, default: false
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
