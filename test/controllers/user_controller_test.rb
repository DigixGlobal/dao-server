# frozen_string_literal: true

require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create user should work' do
    params = attributes_for(:user)

    info_post user_new_path,
              payload: params

    assert_response :success,
                    'should work'
    assert_match 'uid', @response.body,
                 'response should be an ok'

    info_post user_new_path,
              payload: params

    assert_response :success,
                    'should not work with the same params'
    assert_match 'error', @response.body,
                 'response should contain validation errors'

    post user_new_path,
         params: {}

    assert_response :forbidden,
                    'should not work with the empty params'
  end

  test 'user details should work' do
    _user, auth_headers, _key = create_auth_user

    get user_details_path,
        headers: auth_headers

    assert_response :success,
                    'should owrk'
    assert_match 'uid', @response.body,
                 'should work'

    get user_details_path

    assert_response :unauthorized,
                    'should fail without authorization'
  end
end
