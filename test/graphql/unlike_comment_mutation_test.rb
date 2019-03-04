# frozen_string_literal: true

require 'test_helper'

class UnlikeCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($commentId: String!) {
      unlikeComment(input: { commentId: $commentId}) {
        comment {
          id
          liked
          likes
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'unlike comment mutation should work' do
    user = create(:user)
    comment = create(:comment)
    attrs = { 'commentId' => comment.id.to_s }

    Comment.like(user, comment)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['unlikeComment']['errors'],
                 'should have no errors'

    data = result['data']['unlikeComment']['comment']

    assert_equal 0, data['likes'],
                 'likes should be incremented'
    refute data['liked'],
           'liked should be set unset'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['unlikeComment']['errors'],
                     'should not allow unliking of the same comment'
  end

  test 'should fail safely' do
    user = create(:user)
    comment = create(:comment)

    Comment.like(user, comment)

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { 'commentId' => 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['unlikeComment']['errors'],
                     'should fail if comment is not found'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: { 'commentId' => comment.id.to_s }
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a normal user'
  end
end
