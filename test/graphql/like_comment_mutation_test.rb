# frozen_string_literal: true

require 'test_helper'

class LikeCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($commentId: String!) {
      likeComment(input: { commentId: $commentId}) {
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

  test 'like comment mutation should work' do
    user = create(:user)
    comment = create(:comment)
    attrs = { 'commentId' => comment.id.to_s }

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['likeComment']['errors'],
                 'should have no errors'

    data = result['data']['likeComment']['comment']

    assert_equal 1, data['likes'],
                 'likes should be incremented'
    assert data['liked'],
           'liked should be set'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['likeComment']['errors'],
                     'should not allow liking of the same comment'
  end

  test 'should fail safely' do
    user = create(:user)
    comment = create(:comment)

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { 'commentId' => 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['likeComment']['errors'],
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
