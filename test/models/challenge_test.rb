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
end
