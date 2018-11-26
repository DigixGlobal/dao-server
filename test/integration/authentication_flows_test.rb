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

  test 'prove challenge should work' do
    key = Eth::Key.new
    user = create(:user, address: key.address.downcase)
    challenge = create(:user_challenge, user_id: user.id)

    user_challenge = challenge.challenge
    params = {
      address: user.address,
      challenge_id: challenge.id,
      signature: key.personal_sign(user_challenge),
      message: user_challenge
    }

    get prove_path, params: params

    assert_response :success,
                    'should work'
    assert_match 'access-token', @response.body,
                 'response should contain access-token'

    get prove_path, params: params
    assert_response :success,
                    'should fail on re-proving'
    assert_match 'challenge_already_proven', @response.body,
                 'response should contain re-prove status '
  end

  test 'prove challenge should fail safely' do
    key = Eth::Key.new
    user = create(:user, address: key.address.downcase)
    challenge = create(:user_challenge, user_id: user.id)

    user_challenge = challenge.challenge
    params = {
      address: user.address,
      challenge_id: challenge.id,
      signature: key.personal_sign(user_challenge),
      message: user_challenge
    }
  end
end
