# frozen_string_literal: true

require 'test_helper'

class CommentThreadTest < ActiveSupport::TestCase
  test 'comment thread should work' do
    proposal = create(:proposal_with_comments, comment_count: 11, comment_depth: 3, comment_ratio: 10)
    parent_comment = proposal.comment.descendants.all.sample

    # Hack to force deterministic ordering with the created_at field
    Comment.in_batches.each do |relation|
      relation.update_all('created_at = FROM_UNIXTIME(id)')
    end

    require 'pp'
    result = parent_comment.user_stage_comments(proposal.user, :idea, {})
    pp result.as_json({}).inspect
  end

  test 'threads property should work' do
    proposal = create(:proposal_with_comments)
    user = create(:user)

    # Hack to force deterministic ordering with the created_at field
    Comment.in_batches.each do |relation|
      relation.update_all('created_at = FROM_UNIXTIME(id)')
    end

    threads = proposal.user_threads(user)
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
                 proposal.user_threads(user).fetch(proposal.stage, []).first.id,
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
