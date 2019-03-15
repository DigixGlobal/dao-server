# frozen_string_literal: true

require 'test_helper'

class UnpostCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($commentId: String!) {
      unpostComment(input: { commentId: $commentId}) {
        comment {
          id
        }
        errors {
          field
          message
        }
      }
    }
  EOS

  test 'unpost comment mutation should work' do
    comment = create(:comment)
    attrs = { 'commentId' => comment.id.to_s }

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: comment.user },
      variables: attrs
    )

    assert_nil result['errors'],
               'should work and have no errors'
    assert_empty result['data']['unpostComment']['errors'],
                 'should have no errors'

    data = result['data']['unpostComment']['comment']

    assert_nil data['body'],
               'body should be empty'

    repeat_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: comment.user },
      variables: attrs
    )

    assert_not_empty repeat_result['data']['unpostComment']['errors'],
                     'should not allow unposting of the same comment'
  end

  test 'should fail safely' do
    comment = create(:comment)

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: comment.user },
      variables: { 'commentId' => 'NON_EXISTENT_ID' }
    )

    assert_not_empty not_found_result['data']['unpostComment']['errors'],
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
