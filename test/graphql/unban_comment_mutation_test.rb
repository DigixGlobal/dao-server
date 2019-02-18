# frozen_string_literal: true

require 'test_helper'

class UnbanCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($commentId: String!) {
      unbanComment(input: { commentId: $commentId}) {
        comment {
          id
          body
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'unban comment mutation should work' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: true)
    attrs = { 'commentId' => comment.id.to_s }

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['unbanComment']['errors'],
                 'should have no errors'

    data = result['data']['unbanComment']['comment']

    assert data['body'],
           'body should be revealed'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['unbanComment']['errors'],
                     'should not allow unbanning of the same comment'
  end

  test 'should fail safely' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: true)
    comment.discard
    attrs = { 'commentId' => comment.id.to_s }

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
      variables: { 'commentId' => 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['unbanComment']['errors'],
                     'should fail if comment is not found'

    auth_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: attrs
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current comment'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: create(:user) },
      variables: attrs
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail with a normal user'
  end
end
