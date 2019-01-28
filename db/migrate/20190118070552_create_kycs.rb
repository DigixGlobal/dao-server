# frozen_string_literal: true

class CreateKycs < ActiveRecord::Migration[5.2]
  def change
    create_table :kycs do |t|
      t.integer :status
      t.string :first_name
      t.string :last_name
      t.integer :gender
      t.date :birthdate
      t.string :nationality
      t.string :birth_country
      t.string :phone_number
      t.integer :employment_status
      t.string :employment_industry
      t.string :income_range
      t.integer :identification_proof_type
      t.date :identification_proof_expiration_date
      t.string :identification_proof_number
      t.integer :residence_proof_type
      t.string :country
      t.string :address
      t.string :address_details, null: true
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :verification_code
      t.date :expiration_date
      t.string :rejection_reason
      t.string :approval_txhash
      t.datetime :discarded_at

      t.references :user, foreign_key: true
      t.references :officer, foreign_key: false, column: :officer_id, name: :fk_rails_officer_id

      t.timestamps
    end

    add_index :kycs, :discarded_at
    add_index :kycs, :status
  end
end
