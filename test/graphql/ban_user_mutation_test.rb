# frozen_string_literal: true

require 'test_helper'

class BanUserMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($uid: String!) {
      banUser(input: { uid: $uid}) {
        user {
          id
          canComment
          isBanned
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'ban user mutation should work' do
    forum_admin = create(:forum_admin_user)
    user = create(:user, is_banned: false)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { uid: user.uid }
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['banUser']['errors'],
                 'should have no errors'

    data = result['data']['banUser']['user']

    assert data['isBanned'],
           'should be banned'
    refute data['canComment'],
           'should not be able to comment'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { uid: user.uid }
    )

    assert_not_empty repeat_result['data']['banUser']['errors'],
                     'should not allow banning of the same user'
  end

  test 'should fail safely' do
    forum_admin = create(:forum_admin_user)

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: {}
    )

    assert_not_empty empty_result['errors'],
                     'should fail with empty data'

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { uid: 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['banUser']['errors'],
                     'should fail if user is not found'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: { uid: forum_admin.uid }
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: { uid: forum_admin.uid }
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a normal user'

    invalid_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { uid: forum_admin.uid }
    )

    assert_not_empty invalid_result['data']['banUser']['errors'],
                     'should fail to ban self '
  end
end
