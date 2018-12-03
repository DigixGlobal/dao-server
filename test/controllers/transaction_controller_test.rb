# frozen_string_literal: true

require 'test_helper'

class TransactionControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create new transaction should work' do
    stub_request(:any, /transactions/)
      .to_return(body: {
        result: {
          seen: [attributes_for(:transaction)],
          confirmed: [attributes_for(:transaction)]
        }
      }.to_json)

    key = Eth::Key.new
    create(:user, address: key.address)
    params = attributes_for(:transaction)
    auth_headers = auth_headers(key)

    post transactions_path,
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'title', @response.body,
                 'response should contain ok status'

    post transactions_path,
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should fail on retry'
    assert_match 'error', @response.body,
                 'response should contain errors'
  end

  test 'create new transaction can fail safely' do
    stub_request(:any, /transactions/)
      .to_return(body: {
        result: {
          seen: [attributes_for(:transaction)],
          confirmed: [attributes_for(:transaction)]
        }
      }.to_json)

    key = Eth::Key.new
    create(:user, address: key.address)
    params = attributes_for(:transaction)
    auth_headers = auth_headers(key)

    post transactions_path,
         params: params

    assert_response :unauthorized,
                    'should fail on without authorization'

    post transactions_path,
         headers: auth_headers

    assert_response :success,
                    'should fail on with empty data'
    assert_match 'error', @response.body,
                 'response should contain validation errors'
  end

  test 'list transaction should work' do
    key = Eth::Key.new
    user = create(:user, address: key.address)
    10.times do
      create(:transaction, user: user)
    end

    auth_headers = auth_headers(key)

    post transactions_path,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'title', @response.body,
                 'response should contain ok status'

    post transactions_path

    assert_response :unauthorized,
                    'should fail on without authorization'
  end

  test 'confirm transactions should work' do
    transactions = (1..10).map do |_|
      create(:transaction)
    end

    path = transactions_update_path('confirmed')

    put path,
        params: { payload: transactions }.to_json,
        headers: info_server_headers(
          'PUT',
          path,
          transactions
        )

    assert_response :success,
                    'should work'
    assert_match 'confirmed', @response.body,
                 'response should be ok'

    Transaction.all.each do |txn|
      assert_equal 'confirmed', txn.status
    end

    put path,
        params: { payload: transactions }.to_json

    assert_response :forbidden,
                    'should fail without a signature'

    put transactions_update_path('invalid_action'),
        params: { payload: {} }.to_json,
        headers: info_server_headers(
          'PUT',
          transactions_update_path('invalid_action'),
          {}
        )

    assert_response :unprocessable_entity,
                    'should fail if the action is incorrect'
  end

  test 'latest transactions should work' do
    transactions = (1..10).map do |_|
      create(:transaction)
    end

    payload = {
      transactions: transactions,
      blockNumber: generate(:block_number)
    }

    path = transactions_update_path('seen')

    put path,
        params: { payload: payload }.to_json,
        headers: info_server_headers(
          'PUT',
          path,
          payload
        )

    assert_response :success,
                    'should work'
    assert_match 'seen', @response.body,
                 'response should say ok'

    Transaction.all.each do |txn|
      assert_equal 'seen', txn.status
    end

    put path,
        params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without a signature'

    put transactions_update_path('invalid_action'),
        params: { payload: {} }.to_json,
        headers: info_server_headers(
          'PUT',
          transactions_update_path('invalid_action'),
          {}
        )

    assert_response :unprocessable_entity,
                    'should fail if the action is incorrect'
  end

  test 'find transaction should work' do
    transaction = create(:transaction)

    get transaction_path,
        params: { txhash: transaction.txhash }

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should give the transaction'

    get transaction_path,
        params: { txhash: 'NON_EXISTENT_HASH' }

    assert_response :success,
                    'should fail with invalid hash'
    assert_match 'error', @response.body,
                 'response should give transaction missing error'
  end

  test 'test server should work' do
    payload = generate(:txhash)
    path = "#{transactions_ping_path}?payload=#{payload}"

    get path,
        headers: info_server_headers(
          'GET',
          path,
          payload
        )

    assert_response :success,
                    'should work'
    assert_match 'ok', @response.body,
                 'response should say ok'

    get path

    assert_response :forbidden,
                    'should fail without authorization'
  end
end
