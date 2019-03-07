# frozen_string_literal: true

require 'test_helper'

class BanCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($commentId: String!) {
      banComment(input: { commentId: $commentId}) {
        comment {
          id
          body
          isBanned
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  UNAUTHORIZED_QUERY = <<~EOS
    mutation($commentId: String!) {
      banComment(input: { commentId: $commentId}) {
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

  test 'ban comment mutation should work' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: false)
    attrs = { 'commentId' => comment.id.to_s }

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['banComment']['errors'],
                 'should have no errors'

    data = result['data']['banComment']['comment']

    assert data['body'],
           'body should be visible as forum admin'
    assert data['isBanned'],
           'isBanned should be set'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['banComment']['errors'],
                     'should not allow banning of the same comment'
  end

  test 'should fail safely' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: false)
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

    assert_not_empty not_found_result['data']['banComment']['errors'],
                     'should fail if comment is not found'

    auth_result = DaoServerSchema.execute(
      UNAUTHORIZED_QUERY,
      context: {},
      variables: { 'commentId' => comment.id }
    )

    assert_not_empty auth_result['errors'],
                     'should fail without a current user'

    unauthorized_result = DaoServerSchema.execute(
      UNAUTHORIZED_QUERY,
      context: { current_user: create(:user) },
      variables: attrs
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a normal user'

    banned_comment = create(:comment, is_banned: false)
    banned_comment.discard

    invalid_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: forum_admin },
      variables: { 'commentId' => banned_comment.id.to_s }
    )

    assert_not_empty invalid_result['data']['banComment']['errors'],
                     'should not allow banned comments to be banned '
  end
end
