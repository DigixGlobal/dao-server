# frozen_string_literal: true

class CreateDummyTestTable < ActiveRecord::Migration[5.2]
  def change
    create_table :test_images do |t|
    end
  end
end
