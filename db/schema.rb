# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_190_118_070_552) do
  create_table 'active_storage_attachments', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'record_type', null: false
    t.bigint 'record_id', null: false
    t.bigint 'blob_id', null: false
    t.datetime 'created_at', null: false
    t.index ['blob_id'], name: 'index_active_storage_attachments_on_blob_id'
    t.index %w[record_type record_id name blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
  end

  create_table 'active_storage_blobs', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'key', null: false
    t.string 'filename', null: false
    t.string 'content_type'
    t.text 'metadata'
    t.bigint 'byte_size', null: false
    t.string 'checksum', null: false
    t.datetime 'created_at', null: false
    t.index ['key'], name: 'index_active_storage_blobs_on_key', unique: true
  end

  create_table 'challenges', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'challenge'
    t.boolean 'proven', default: false
    t.bigint 'user_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_challenges_on_user_id'
  end

  create_table 'comment_hierarchies', id: false, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.integer 'ancestor_id', null: false
    t.integer 'descendant_id', null: false
    t.integer 'generations', null: false
    t.index %w[ancestor_id descendant_id generations], name: 'comment_anc_desc_idx', unique: true
    t.index ['descendant_id'], name: 'comment_desc_idx'
  end

  create_table 'comment_likes', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.bigint 'user_id'
    t.bigint 'comment_id'
    t.index ['comment_id'], name: 'index_comment_likes_on_comment_id'
    t.index %w[user_id comment_id], name: 'index_comment_likes_on_user_id_and_comment_id', unique: true
    t.index ['user_id'], name: 'index_comment_likes_on_user_id'
  end

  create_table 'comments', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.text 'body'
    t.integer 'stage', default: 1
    t.bigint 'user_id'
    t.integer 'likes', default: 0
    t.integer 'parent_id'
    t.datetime 'discarded_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['discarded_at'], name: 'index_comments_on_discarded_at'
    t.index ['stage'], name: 'index_comments_on_stage'
    t.index ['user_id'], name: 'index_comments_on_user_id'
  end

  create_table 'kyc_documents', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.integer 'document_type', null: false
    t.integer 'issuing_country', null: false
    t.datetime 'expires_at', null: false
    t.string 'file_name', null: false
    t.integer 'file_size', null: false
    t.string 'content_type', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'kycs', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.integer 'status'
    t.string 'first_name'
    t.string 'last_name'
    t.integer 'gender'
    t.date 'birth_date'
    t.string 'nationality'
    t.string 'phone_number'
    t.integer 'employment_status'
    t.string 'employment_industry'
    t.string 'income_range'
    t.integer 'identification_proof_type'
    t.date 'identification_proof_date'
    t.string 'identification_proof_number'
    t.string 'residence_proof_type'
    t.string 'country'
    t.string 'address'
    t.string 'address_details'
    t.string 'city'
    t.string 'state'
    t.string 'postal_code'
    t.bigint 'user_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_kycs_on_user_id'
  end

  create_table 'nonces', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'server'
    t.integer 'nonce'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'proposal_likes', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.bigint 'user_id'
    t.bigint 'proposal_id'
    t.index ['proposal_id'], name: 'index_proposal_likes_on_proposal_id'
    t.index %w[user_id proposal_id], name: 'index_proposal_likes_on_user_id_and_proposal_id', unique: true
    t.index ['user_id'], name: 'index_proposal_likes_on_user_id'
  end

  create_table 'proposals', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'proposal_id', default: '', null: false
    t.bigint 'user_id'
    t.integer 'stage', default: 1
    t.integer 'likes', default: 0
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'comment_id'
    t.index ['comment_id'], name: 'index_proposals_on_comment_id'
    t.index ['proposal_id'], name: 'index_proposals_on_proposal_id', unique: true
    t.index ['stage'], name: 'index_proposals_on_stage'
    t.index ['user_id'], name: 'index_proposals_on_user_id'
  end

  create_table 'transactions', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'title'
    t.string 'txhash'
    t.string 'status', default: 'pending'
    t.integer 'block_number'
    t.bigint 'user_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['txhash'], name: 'index_transactions_on_txhash', unique: true
    t.index ['user_id'], name: 'index_transactions_on_user_id'
  end

  create_table 'user_audits', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.integer 'user_id', null: false
    t.string 'event', null: false
    t.string 'field', null: false
    t.string 'old_value', null: false
    t.string 'new_value', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
    t.string 'provider', default: 'address', null: false
    t.string 'uid', default: '', null: false
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'address', default: '0x0', null: false
    t.text 'tokens'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'username'
    t.string 'email', limit: 20
    t.index ['address'], name: 'index_users_on_address', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index %w[uid provider], name: 'index_users_on_uid_and_provider', unique: true
    t.index ['username'], name: 'index_users_on_username', unique: true
  end

  add_foreign_key 'challenges', 'users'
  add_foreign_key 'comments', 'users'
  add_foreign_key 'kycs', 'users'
  add_foreign_key 'proposals', 'comments'
  add_foreign_key 'proposals', 'users'
  add_foreign_key 'transactions', 'users'
end
