# frozen_string_literal: true

require 'test_helper'

class PostCommentMutationTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    mutation($proposalId: String, $commentId: String, $body: String!) {
      postComment(input: { proposalId: $proposalId, commentId: $commentId, body: $body}) {
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

  test 'post comment mutation should work' do
    user = create(:user)
    proposal = create(:proposal)
    attrs = {
      'proposalId' => proposal.proposal_id,
      'body' => generate(:comment_body)
    }

    proposal_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: attrs
    )

    assert_nil proposal_result['errors'],
               'should work with proposal id and have no errors'
    assert_empty proposal_result['data']['postComment']['errors'],
                 'should have no errors'

    data = proposal_result['data']['postComment']['comment']

    assert_equal attrs['body'], data['body'],
                 'body should be the same'

    comment_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: {
        'commentId' => proposal.comment.id.to_s,
        'body' => generate(:comment_body)
      }
    )

    assert_nil comment_result['errors'],
               'should work with comment id and have no errors'
  end

  test 'should fail safely' do
    user = create(:user)
    proposal = create(:proposal)

    empty_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { 'proposalId' => proposal.proposal_id, body: '' }
    )

    assert_not_empty empty_result['data']['postComment']['errors'],
                     'should fail with empty data'

    no_proposal_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { 'proposalId' => 'NON_EXISTENT_ID', body: 'PROPOSAL' }
    )

    assert_not_empty no_proposal_result['data']['postComment']['errors'],
                     'should fail if proposal is not found'

    no_comment_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { 'commentId' => 'NON_EXISTENT_ID', body: 'COMMENT' }
    )

    assert_not_empty no_comment_result['data']['postComment']['errors'],
                     'should fail if comment is not found'

    not_found_result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: { body: 'COMMENT' }
    )

    assert_not_empty not_found_result['data']['postComment']['errors'],
                     'should fail if comment is not found'

    unauthorized_result = DaoServerSchema.execute(
      QUERY,
      context: {},
      variables: { 'body' => 'MEOW' }
    )

    assert_not_empty unauthorized_result['errors'],
                     'should fail without a user'
  end
end
