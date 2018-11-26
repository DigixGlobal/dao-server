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

    post prove_path, params: params

    assert_response :success,
                    'should work'
    assert_match 'access-token', @response.body,
                 'response should contain access-token'

    post prove_path, params: params
    assert_response :success,
                    'should fail on re-proving'
    assert_match 'challenge_already_proven', @response.body,
                 'response should contain re-prove status'
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

    post prove_path, params: {}

    assert_response :success,
                    'should fail with empty data'
    assert_match 'invalid_data', @response.body,
                 'response should contain invalid parameter status'

    post prove_path, params: params.merge(challenge_id: :incorrect_id)

    assert_response :success,
                    'should fail with incorrect challenge id'
    assert_match 'challenge_not_found', @response.body,
                 'response should contain challenge not found status'

    post prove_path, params: params.merge(address: :incorrect_address)

    assert_response :success,
                    'should fail with incorrect address'
    assert_match 'address_not_equal', @response.body,
                 'response should contain address not equal not status'

    post prove_path, params: params.merge(message: :incorrect_challenge)

    assert_response :success,
                    'should fail with incorrect message'
    assert_match 'challenge_failed', @response.body,
                 'response should contain address challenge failed status'
  end
end
