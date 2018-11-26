# frozen_string_literal: true

require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    Nonce.delete_all

    create(:server_nonce, server: 'infoServer')
  end

  test 'create user should work' do
    params = attributes_for(:user)

    post user_new_path,
         params: { payload: params }.to_json,
         headers: info_server_headers('POST', user_new_path, params)

    assert_response :success,
                    'should work'

    post user_new_path,
         params: { payload: params }.to_json,
         headers: info_server_headers('POST', user_new_path, params)

    assert_response :unprocessable_entity,
                    'should not work with the same params'

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
  end
end
