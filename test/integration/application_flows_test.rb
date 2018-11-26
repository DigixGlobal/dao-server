# frozen_string_literal: true

require 'test_helper'

class ApplicationFlowsTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    Challenge.delete_all
  end

  test 'application can handle 404' do
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
end
