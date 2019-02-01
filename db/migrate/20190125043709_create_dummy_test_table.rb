# frozen_string_literal: true

class CreateDummyTestTable < ActiveRecord::Migration[5.2]
  def change
    if Rails.env.test?
      create_table :test_images do |t|
      end
    end
  end
end
