# frozen_string_literal: true

class CreateKycDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :kyc_documents do |t|
      t.integer :document_type, null: false
      # t.attachment :document, null: false
      t.integer :issuing_country, null: false
      t.datetime :expires_at, null: false
      t.string :file_name, null: false
      t.integer :file_size, null: false
      t.string :content_type, null: false
      t.timestamps
    end
  end
end
