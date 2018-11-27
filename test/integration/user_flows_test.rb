# frozen_string_literal: true

require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    Nonce.delete_all

    create(:server_nonce, server: Rails.configuration.nonces['info_server_name'])
  end

  test 'create user should work' do
    params = attributes_for(:user)

    post user_new_path,
         params: { payload: params }.to_json,
         headers: info_server_headers('POST', user_new_path, params)

    assert_response :success,
                    'should work'
    assert_match 'ok', @response.body,
                 'response should be an ok'

    post user_new_path,
         params: { payload: params }.to_json,
         headers: info_server_headers('POST', user_new_path, params)

    assert_response :success,
                    'should not work with the same params'
    assert_match 'errors', @response.body,
                 'response should contain validation errors'

    post user_new_path,
         params: {}.to_json,
         headers: info_server_headers('POST', user_new_path, {})

    assert_response :forbidden,
                    'should not work with the empty params'
  end

  test 'user details should work' do
    key = Eth::Key.new
    create(:user, address: key.address)

    get user_details_path,
        headers: auth_headers(key)

    assert_response :success,
                    'should work'
    assert_match 'uid', @response.body,
                 'should work'

    get user_details_path

    assert_response :unauthorized,
                    'should fail without authorization'
  end
end
