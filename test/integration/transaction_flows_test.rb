# frozen_string_literal: true

require 'test_helper'

class TransactionFlowsTest < ActionDispatch::IntegrationTest
  setup do
    Transaction.delete_all
    User.delete_all
    Nonce.delete_all

    create(:server_nonce, server: Rails.configuration.nonces['info_server_name'])
    create(:server_nonce, server: Rails.configuration.nonces['self_server_name'])
  end

  test 'create new transaction should work' do
    stub_request(:any, /transactions/)
      .to_return(body: { result: { seen: [], confirmed: [] } }.to_json)

    key = Eth::Key.new
    create(:user, address: key.address)
    params = attributes_for(:transaction)
    auth_headers = auth_headers(key)

    post transactions_new_path,
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'ok', @response.body,
                 'response should contain ok status'

    post transactions_new_path,
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should fail on retry'
    assert_match 'errors', @response.body,
                 'response should contain errors'
  end
end
