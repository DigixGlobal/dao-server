# frozen_string_literal: true

require 'test_helper'

class ViewerQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query {
      viewer {
        id
        email
        address
        username
        displayName
        createdAt
      }
    }
  EOS

  test 'viewer query should work' do
    user = create(:user)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: {}
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['viewer']

    assert_equal "user#{user.id}", data['displayName'],
                 'display name should default'

    new_username = generate(:username)
    ok, updated_user = User.change_username(user, new_username)

    assert_equal :ok, ok,
                 'change username should work'

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: updated_user },
      variables: {}
    )

    assert_equal new_username, result['data']['viewer']['displayName'],
                 'display name should now be the username'
  end

  test 'should fail without a current user' do
    result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: {}
    )

    assert_not_empty result['errors'],
                     'should fail without a current user'
  end
end
