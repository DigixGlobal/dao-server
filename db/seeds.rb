# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

def add_user(address, uid)
  return if User.find_by(address: address)
  u = User.new(address: address, uid: uid)
  u.save
end

def add_nonce(server, nonce)
  return if Nonce.find_by(server: server)
  n = Nonce.new(server: server, nonce: nonce)
  n.save
end

def add_pending_txns(title, txhash)
  return if Transaction.find_by(txhash: txhash)
  t = Transaction.new(title: title, txhash: txhash, user_id: '1')
  t.save
end

add_user('0x68911e512a4ecbd12d5dbae3250ff2c8e5850b60', '01')
add_user('0x300ac2c15a6778cfdd7eaa6189a4401123ff9dda', '02')
add_user('0x602651daaea32f5a13d9bd4df67d0922662e8928', '03')
add_user('0x9210ddf37582861fbc5ec3a9aff716d3cf9be5e1', '04')
add_user('0xe02a693f038933d7b28301e6fb654a035385652d', '05')
add_user('0xcbe85e69eec80f29e9030233a757d49c68e75c8d', '06')
add_user('0x355fbd38b3219fa3b7d0739eae142acd9ea832a1', '07')

add_nonce('self', 0)
add_nonce('infoServer', 0)

add_pending_txns('title aaa', '0xaaa')
add_pending_txns('title bbb', '0xbbb')
