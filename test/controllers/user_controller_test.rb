# frozen_string_literal: true

require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  test 'create user should work' do
    params = attributes_for(:user)

    assert_self_nonce_increased do
      info_post user_path,
                payload: params
    end

    assert_response :success,
                    'should work'
    assert_match 'address', @response.body,
                 'response should be an ok'

    info_post user_path,
              payload: params

    assert_response :success,
                    'should not work with the same params'
    assert_match 'error', @response.body,
                 'response should contain validation errors'

    post user_path,
         params: {}

    assert_response :forbidden,
                    'should not work with the empty params'
  end

  test 'user details should work' do
    _user, auth_headers, _key = create_auth_user

    get user_path,
        headers: auth_headers

    assert_response :success,
                    'should owrk'
    assert_match 'address', @response.body,
                 'should work'

    get user_path

    assert_response :unauthorized,
                    'should fail without authorization'
  end
end
