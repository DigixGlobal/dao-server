# frozen_string_literal: true

require 'test_helper'

class ChangeUsernameMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($username: String!) {
      changeUsername(input: {username: $username}) {
        user {
          username
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'change username mutation should work' do
    user = create(:user)
    username = generate(:username)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { username: username }
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['changeUsername']['errors'],
                 'should have no errors'

    assert_equal username, result['data']['changeUsername']['user']['username'],
                 'username should be updated'

    set_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: User.find(user.id) },
      variables: { username: username }
    )

    assert_equal 'Username already set',
                 set_result['data']['changeUsername']['errors'][0]['message'],
                 'username should be updated'
  end

  test 'should fail safely' do
    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: { username: '' }
    )

    assert_not_empty empty_result['data']['changeUsername']['errors'],
                     'should fail on empty data'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'
  end
end
