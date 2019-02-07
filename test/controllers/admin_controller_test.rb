# frozen_string_literal: true

require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  test 'update KYC hashes should work' do
    path = admin_kyc_path
    hashes = create_list(:kyc, 5)
             .map do |kyc|
      { address: kyc.user.address, txhash: generate(:txhash) }
    end
    payload = { approved: hashes }

    assert_self_nonce_increased do
      info_post path,
                payload: payload
    end

    assert_response :success,
                    'should work'
    assert_match 'result', @response.body,
                 'response should be ok'

    post path,
         params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without a signature'

    info_post path,
              payload: {}

    assert_response :success,
                    'should work safely even with empty data'
  end
end
