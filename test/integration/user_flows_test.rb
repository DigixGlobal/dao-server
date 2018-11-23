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
         params: { payload: params },
         headers: info_server_headers(user_new_path, params)

    assert_response :success,
                    'should work'
  end
end
