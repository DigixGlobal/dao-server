# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'factory_bot'

def is_unique_uid(uid)
  if User.find_by(uid: uid)
    false
  else
    true
  end
end

def add_user(address)
  return if User.find_by(address: address)

  uid = Random.rand(1_000_000)
  uid = Random.rand(1_000_000) until is_unique_uid(uid)
  u = User.new(address: address, uid: uid)
  u.save
end

def add_pending_txns(title, txhash)
  return if Transaction.find_by(txhash: txhash)

  t = Transaction.new(title: title, txhash: txhash, user_id: '1')
  t.save
end

Transaction.delete_all
CommentLike.delete_all
ProposalLike.delete_all
Proposal.delete_all
Comment.delete_all
CommentHierarchy.delete_all
Challenge.delete_all
Kyc.delete_all
Group.delete_all
User.delete_all
Nonce.delete_all

# add_user('0x68911e512a4ecbd12d5dbae3250ff2c8e5850b60')
# add_user('0x300ac2c15a6778cfdd7eaa6189a4401123ff9dda')
# add_user('0x602651daaea32f5a13d9bd4df67d0922662e8928')
# add_user('0x9210ddf37582861fbc5ec3a9aff716d3cf9be5e1')
# add_user('0xe02a693f038933d7b28301e6fb654a035385652d')
# add_user('0xcbe85e69eec80f29e9030233a757d49c68e75c8d')
# add_user('0x355fbd38b3219fa3b7d0739eae142acd9ea832a1')

Nonce.seed
Group.seed
User.seed

# add_pending_txns('title aaa', '0xaaa')
# add_pending_txns('title bbb', '0xbbb')

FactoryBot.find_definitions

puts 'Seeding proposals with comments'
3.times do
  proposal = FactoryBot.create(:proposal_with_comments)
  puts "Created a proposal #{proposal.id}"
end

puts 'Seeding kycs'
1.times do
  kyc = FactoryBot.create(:pending_kyc)
  puts "Created a pending kyc #{kyc.id}"
end
