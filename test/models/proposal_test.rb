# frozen_string_literal: true

require 'test_helper'

class ProposalTest < ActiveSupport::TestCase
  setup :database_fixture

  test 'create new proposal should work' do
    user = create(:user)
    params = attributes_for(
      :proposal,
      id: generate(:proposal_id),
      proposer: user.address
    )

    ok, proposal = Proposal.create_proposal(params)

    assert_equal :ok, ok,
                 'should work'
    assert_equal params.fetch(:id), proposal.id,
                 'proposal should respect the id'
    assert_equal :idea, proposal.stage.to_sym,
                 'proposal should be at the idea stage'

    user_not_found, = Proposal.create_proposal(
      params.merge(proposer: 'NON_EXISTENT')
    )

    assert_equal :invalid_data, user_not_found,
                 'user should exist when creating proposals'

    invalid_data, = Proposal.create_proposal(params)

    assert_equal :invalid_data, invalid_data,
                 'adding the same proposal should fail'

    invalid_data, = Proposal.create_proposal({})

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'
  end

  test 'comment on post should work' do
    proposal = create(:proposal)
    user = proposal.user
    attrs = attributes_for(:comment)

    ok, comment = Proposal.comment(proposal, user, nil, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Comment, comment,
                   'result should be a comment'
    assert_equal proposal.stage, comment.stage,
                 'comment and proposal should have the same stage/status'

    ok, other_comment = Proposal.comment(proposal, user, nil, attrs)

    assert_equal :ok, ok,
                 'making the same comment should work'
    assert_not_equal comment.id, other_comment.id,
                     'other comments should be different'

    invalid_data, = Proposal.comment(proposal, user, nil, {})

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'
  end

  test 'reply on comment post should work' do
    proposal = create(:proposal_with_comments)
    parent_comment = proposal.comments.sample
    user = create(:user)
    attrs = attributes_for(:comment)

    ok, comment = Proposal.comment(proposal, user, parent_comment, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal parent_comment.id, comment.parent_id,
                 'should be linked to its parent'
    assert parent_comment.children.find(comment.id),
           'created comment should be a child/reply of the comment'
  end

  test 'comment reply depth limit should work' do
    proposal = create(:proposal)
    attrs = attributes_for(:comment)

    limit = Rails.configuration.proposals['comment_max_depth'].to_i

    parent_comment = nil
    limit.times do
      ok, parent_comment = Proposal.comment(
        proposal,
        proposal.user,
        parent_comment,
        attrs
      )

      assert_equal :ok, ok,
                   'should work while limit is not reached'
    end

    maximum_comment_depth, = Proposal.comment(
      proposal,
      proposal.user,
      parent_comment,
      attrs
    )

    assert_equal :maximum_comment_depth, maximum_comment_depth,
                 'should fail if limit is reached'
  end

  test 'delete comment should work' do
    proposal = create(:proposal_with_comments)
    comment = proposal.comments.sample
    child_comment = create(:comment, parent: comment)

    ok, deleted_comment = Comment.delete(comment.user, comment)

    assert_equal :ok, ok,
                 'should work'
    assert deleted_comment.discarded?,
           'comment should be deleted'
    assert_not Comment.find(child_comment.id).discarded?,
               'child comment should not be deleted'

    another_comment = create(:comment)

    unauthorized_action, = Comment.delete(comment.user, another_comment)

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow other users to delete'
  end

  test 'deleted replies should be found and still be commented' do
    proposal = create(:proposal_with_comments)
    comment = proposal.comments.sample
    child_comment = create(:comment, parent: comment)
    discarded_comment = create(:comment, parent: comment)

    ok, = Comment.delete(discarded_comment.user, discarded_comment)

    assert_equal :ok, ok,
                 'should work'
    assert comment.children.find_by(id: discarded_comment.id),
           'should find deleted comment'
    assert comment.children.find_by(id: child_comment.id),
           'should still find other comment'

    ok, = Proposal.comment(
      proposal,
      child_comment.user,
      discarded_comment,
      attributes_for(:comment)
    )

    assert_equal :ok, ok,
                 'can reply to deleted comments/replies'
  end

  test 'threads property should work' do
    proposal = create(:proposal_with_comments)
    user = create(:user)

    # Hack to force deterministic ordering with the created_at field
    Comment.in_batches.each do |relation|
      relation.update_all('created_at = FROM_UNIXTIME(id)')
    end

    threads = proposal.reload.user_threads(user)
    assert threads,
           'should work'

    comments = flatten_threads(threads)

    assert_not comments.any?(&:discarded?),
               'no deleted comments should exsist'
    assert comments.all? { |comment| comment.proposal_id == proposal.id },
           'comments should use the same proposal'
    assert_equal Comment.where(proposal_id: proposal.id).size, comments.size,
                 'comments should be the same'

    new_comment = create(:comment, proposal: proposal, stage: proposal.stage)

    assert_equal new_comment.id,
                 proposal.reload.user_threads(user).fetch(proposal.stage, []).first.id,
                 'new comment should be first in the list'
  end

  private

  def flatten_threads(threads)
    threads
      .values
      .map do |stage_comments|
        stage_comments.map { |comment| flatten_comment_tree(comment) }
      end
      .flatten
  end

  def flatten_comment_tree(comment)
    replies = comment.replies || []
    comment.replies = nil
    [comment, replies.map { |reply| flatten_comment_tree(reply) }].flatten
  end
end
