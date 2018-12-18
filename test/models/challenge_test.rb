# frozen_string_literal: true

require 'test_helper'

class ChallengeTest < ActiveSupport::TestCase
  test 'create new challenge should work' do
    user = create(:user)
    params = { address: user.address }

    ok, challenge = Challenge.create_new_challenge(params)

    assert_equal :ok, ok,
                 'should work'
    assert_not challenge.proven,
               'challenge should be initially unproven'
    assert_equal user.id, challenge.user_id,
                 'challenge should be linked to the user'

    user_not_found, = Challenge.create_new_challenge(address: 'NON_EXISTENT_ADDRESS')

    assert_equal :user_not_found, user_not_found,
                 'user should not be found'

    user_not_found, = Challenge.create_new_challenge({})

    assert_equal :user_not_found, user_not_found,
                 'should fail with empty data'
  end

  test 'create new challenge should clean data properly' do
    this_user = create(:user)
    that_user = create(:user)

    this_params = { address: this_user.address }
    that_params = { address: that_user.address }

    _ok, this_challenge = Challenge.create_new_challenge(this_params)
    _ok, _that_challenge = Challenge.create_new_challenge(that_params)

    assert Challenge.find(this_challenge.id),
           "should not cleanup other user's challenge"

    _ok, my_new_challenge = Challenge.create_new_challenge(this_params)

    assert_not Challenge.find_by(id: this_challenge.id),
               'should cleanup previous challenge'

    my_new_challenge.update(proven: true)

    _ok, _my_newer_challenge = Challenge.create_new_challenge(that_params)

    assert Challenge.find(my_new_challenge.id),
           'should not cleanup previously proven challenge'
  end

  test 'prove challenge should work' do
    key = Eth::Key.new
    user = create(:user, address: key.address.downcase)
    challenge = create(:user_challenge, user_id: user.id)

    user_challenge = challenge.challenge
    attrs = {
      address: user.address,
      signature: key.personal_sign(user_challenge),
      message: user_challenge
    }

    ok, proven_challenge = Challenge.prove_challenge(
      challenge,
      attrs
    )

    assert_equal :ok, ok,
                 'should work'
    assert proven_challenge.proven,
           'challenge should be proven'

    challenge_already_proven, = Challenge.prove_challenge(
      challenge,
      attrs
    )

    assert_equal :challenge_already_proven, challenge_already_proven,
                 'should fail with a proven challenge'
  end

  test 'prove challenge should fail safely' do
    key = Eth::Key.new
    user = create(:user, address: key.address.downcase)
    challenge = create(:user_challenge, user_id: user.id)

    user_challenge = challenge.challenge
    attrs = {
      address: user.address,
      signature: key.personal_sign(user_challenge),
      message: user_challenge
    }

    address_not_equal, = Challenge.prove_challenge(
      challenge,
      {}
    )

    assert_equal :address_not_equal, address_not_equal,
                 'should fail with empty data'

    challenge_failed, = Challenge.prove_challenge(
      challenge,
      address: user.address
    )

    assert_equal :challenge_failed, challenge_failed,
                 'should fail without signature or message'

    challenge_failed, = Challenge.prove_challenge(
      challenge,
      address: user.address,
      signature: 'INVALID_SIGNATURE',
      message: user_challenge
    )

    assert_equal :challenge_failed, challenge_failed,
                 'should fail with invalid signature'

    other_key = Eth::Key.new
    create(:user, address: other_key.address.downcase)

    challenge_failed, = Challenge.prove_challenge(
      challenge,
      address: user.address,
      signature: other_key.personal_sign(user_challenge),
      message: user_challenge
    )

    assert_equal :challenge_failed, challenge_failed,
                 'other user should not be able to prove the challenge'
  end
end
