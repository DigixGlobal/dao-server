# frozen_string_literal: true

require 'test_helper'

class WatchingTransactionTest < ActiveSupport::TestCase
  test 'watch should work' do
    user = create(:user)
    attrs = attributes_for(:watching_transaction)
    ok, tx = WatchingTransaction.watch(user, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal user.id, tx.user.id,
                 'should have correct user id'
  end

  test 'resend should work' do
    user = create(:user)
    watching_transaction = create(:watching_transaction, user: user)
    attrs = attributes_for(:watching_transaction)

    ok, tx = WatchingTransaction.resend(user, watching_transaction, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal watching_transaction.group_id, tx.group_id,
                 'should have the same group as the previous transaction'
  end

  test 'resend transactions should keep all if none is mined' do
    user = create(:user)
    group_id = SecureRandom.uuid
    size = SecureRandom.rand(1..6)
    size.times do
      FactoryBot.create(:watching_transaction, group_id: group_id, user: user)
    end

    pending_stub = stub_request(:post, EthereumApi::SERVER_URL)
                   .with(body: /eth_getTransactionByHash/)
                   .to_return(
                     body: {
                       result: {
                         'block_number' => nil
                       }
                     }.to_json
                   )

    WatchingTransaction.resend_transactions

    assert_requested(pending_stub, times: size)
    assert_equal size, WatchingTransaction.where(group_id: group_id).count,
                 'should work'
  end

  test 'resend transactions should destroy all if one is mined' do
    user = create(:user)
    group_id = SecureRandom.uuid
    size = SecureRandom.rand(1..6)
    transaction_group = (1..size).map do
      FactoryBot.create(:watching_transaction, group_id: group_id, user: user)
    end

    pending_stub = stub_request(:post, EthereumApi::SERVER_URL)
                   .with(body: /eth_getTransactionByHash/)
                   .to_return(
                     body: {
                       result: {
                         'block_number' => nil
                       }
                     }.to_json
                   )

    mined_stub = stub_request(:post, EthereumApi::SERVER_URL)
                 .with(body: /eth_getTransactionByHash.*#{transaction_group.sample.txhash}/)
                 .to_return(
                   body: {
                     result: {
                       'block_number' => SecureRandom.hex(8)
                     }
                   }.to_json
                 )

    WatchingTransaction.resend_transactions

    assert_requested(pending_stub, times: size)
    assert_requested(mined_stub, times: 1)
    assert_equal 0, WatchingTransaction.where(group_id: group_id).count,
                 'should destroy all if one is mined'
  end

  test 'resend transactions should resend latest if rest are dropped' do
    user = create(:user)
    group_id = SecureRandom.uuid
    size = SecureRandom.rand(1..6)
    size.times do
      FactoryBot.create(:watching_transaction, group_id: group_id, user: user)
    end
    latest = FactoryBot.create(:watching_transaction, group_id: group_id, user: user, created_at: Date.current + 1)

    dropped_stub = stub_request(:post, EthereumApi::SERVER_URL)
                   .with(body: /eth_getTransactionByHash/)
                   .to_return(
                     body: {
                       result: nil
                     }.to_json
                   )

    new_txhash = generate(:txhash)
    send_transaction_stub = stub_request(:post, EthereumApi::SERVER_URL)
                            .with(body: /eth_sendRawTransaction/)
                            .to_return(
                              body: {
                                result: new_txhash
                              }.to_json
                            )

    WatchingTransaction.resend_transactions

    assert_requested(dropped_stub, times: size + 1)
    assert_requested(send_transaction_stub, times: 1)
    assert_equal 1, WatchingTransaction.where(group_id: group_id).count,
                 'should work'

    resent = WatchingTransaction.find_by(id: latest.id)
    assert_equal new_txhash, resent.txhash,
                 'should update txhash for resent transaction'
  end

  test 'resend transactions should keep all if get transaction fails' do
    user = create(:user)
    group_id = SecureRandom.uuid
    size = SecureRandom.rand(1..6)
    size.times do
      FactoryBot.create(:watching_transaction, group_id: group_id, user: user)
    end

    get_failed_stub = stub_request(:post, EthereumApi::SERVER_URL)
                      .with(body: /eth_getTransactionByHash/)
                      .to_return(status: [500, 'Internal Server Error'])

    WatchingTransaction.resend_transactions

    assert_requested(get_failed_stub, times: 1)
    assert_equal size, WatchingTransaction.where(group_id: group_id).count,
                 'should work'
  end

  test 'resend transactions should keep latest if send transaction fails' do
    user = create(:user)
    group_id = SecureRandom.uuid
    size = SecureRandom.rand(1..6)
    size.times do
      FactoryBot.create(:watching_transaction, group_id: group_id, user: user)
    end
    latest = FactoryBot.create(:watching_transaction, group_id: group_id, user: user, created_at: Date.current + 1)

    dropped_stub = stub_request(:post, EthereumApi::SERVER_URL)
                   .with(body: /eth_getTransactionByHash/)
                   .to_return(
                     body: {
                       result: nil
                     }.to_json
                   )

    send_transaction_failed_stub = stub_request(:post, EthereumApi::SERVER_URL)
                                   .with(body: /eth_sendRawTransaction/)
                                   .to_return(status: [500, 'Internal Server Error'])

    WatchingTransaction.resend_transactions

    assert_requested(dropped_stub, times: size + 1)
    assert_requested(send_transaction_failed_stub, times: 1)

    not_resent = WatchingTransaction.find_by(id: latest.id)
    assert_equal latest.txhash, not_resent.txhash,
                 'should keep txhash'
  end
end
