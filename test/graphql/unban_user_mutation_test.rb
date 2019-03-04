# frozen_string_literal: true

require 'test_helper'

class UnbanUserMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($id: String!) {
      unbanUser(input: { id: $id}) {
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

  test 'unban user mutation should work' do
    forum_admin = create(:forum_admin_user)
    user = create(:user, is_banned: true)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { id: user.id.to_s }
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['unbanUser']['errors'],
                 'should have no errors'

    data = result['data']['unbanUser']['user']

    refute data['isBanned'],
           'should be unbanned'
    assert data['canComment'],
           'should be allowed to comment'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { id: user.id.to_s }
    )

    assert_not_empty repeat_result['data']['unbanUser']['errors'],
                     'should not allow unbanning of the same user'
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
      variables: { id: 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['unbanUser']['errors'],
                     'should fail if user is not found'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: { id: forum_admin.id.to_s }
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: { id: forum_admin.id.to_s }
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a normal user'

    invalid_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { id: forum_admin.id.to_s }
    )

    assert_not_empty invalid_result['data']['unbanUser']['errors'],
                     'should fail to ban self '
  end
end
