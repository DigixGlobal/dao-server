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

add_user('0x68911e512a4ecbd12d5dbae3250ff2c8e5850b60', '01')
add_user('0x300ac2c15a6778cfdd7eaa6189a4401123ff9dda', '02')
add_user('0x602651daaea32f5a13d9bd4df67d0922662e8928', '03')
add_user('0x9210ddf37582861fbc5ec3a9aff716d3cf9be5e1', '04')
add_user('0xe02a693f038933d7b28301e6fb654a035385652d', '05')
add_user('0xcbe85e69eec80f29e9030233a757d49c68e75c8d', '06')
add_user('0x355fbd38b3219fa3b7d0739eae142acd9ea832a1', '07')



add_user('0x9f244f9316426030bca51baf35a4541422ab4f76', '08')
add_user('0x0b2b99eb6850df81452df017d278f97d26426ace', '09')

add_user('0x5d1e440153966c5ab576457f702a1778e27d44c7', '10')

add_user('0x508221f68118d1eaa631d261aca3f2fccc6ecf91', '11')

add_user('0x519774b813dd6de58554219f16c6aa8350b8ec99', '12')

add_user('0xca731a9a354be04b8ebfcd9e429f85f48113d403', '13')

add_user('0x1a4d420bff04e68fb76096ec3cbe981f509c3341', '14')


add_user('0x11ad4d13bcca312e83eec8f961ada76c41c0ef09', '15')

add_user('0xad127e217086779bc0a03b75adee5f5d729aa4eb', '16')

add_user('0x0d4f271e282ddcc7290ad3569458d2c399f34eb6', '17')


add_nonce('self', 0)
add_nonce('infoServer', 0)
