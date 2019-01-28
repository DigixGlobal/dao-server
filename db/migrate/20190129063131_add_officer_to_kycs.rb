# frozen_string_literal: true

class AddOfficerToKycs < ActiveRecord::Migration[5.2]
  def change
    add_reference :kycs, :users,
                  foreign_key: true,
                  column: :officer_id,
                  null: true
  end
end
