# frozen_string_literal: true

require 'test_helper'

class AuthenticationFlowsTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    Challenge.delete_all
  end

  test 'create challenge should work' do
    user = create(:user)
    params = { address: user.address }

    headers = { 'CONTENT-TYPE': 'application/json' }

    get get_challenge_path,
        params: params,
        headers: headers

    assert_response :success,
                    'should work'

    get get_challenge_path,
        params: { address: 'NOT_A_VALID_ADDRESS' },
        headers: headers

    assert_response :not_found,
                    'should not work with invalid address'

    get get_challenge_path,
        params: {},
        headers: headers

    assert_response :not_found,
                    'should not work with empty data'
  end
end
