# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'comment on post should work' do
    proposal = create(:proposal)
    root_comment = proposal.comment
    user = proposal.user
    attrs = attributes_for(:comment)

    ok, comment = Comment.comment(user, root_comment, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Comment, comment,
                   'result should be a comment'
    assert_equal proposal.stage, comment.stage,
                 'comment and proposal should have the same stage/status'
    assert_equal root_comment.id, comment.parent_id,
                 'comment should be linked to the root comment'

    ok, other_comment = Comment.comment(user, root_comment, attrs)

    assert_equal :ok, ok,
                 'making the same comment should work'
    assert_not_equal comment.id, other_comment.id,
                     'other comments should be different'

    unauthorized_action, = Comment.comment(
      user,
      create(:comment, stage: :archived),
      attrs
    )

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow previously staged comment'

    invalid_data, = Comment.comment(user, root_comment, {})

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'
  end

  test 'reply on comment post should work' do
    proposal = create(:proposal_with_comments)
    parent_comment = proposal.comment.descendants.all.sample
    user = create(:user)
    attrs = attributes_for(:comment)

    proposal.update!(stage: parent_comment.stage)
    ok, comment = Comment.comment(user, parent_comment, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_equal parent_comment.id, comment.parent_id,
                 'should be linked to its parent'
    assert parent_comment.children.find(comment.id),
           'should be a child/reply of the comment'
    assert parent_comment.root.descendants.find(comment.id),
           'should be linked to the root comment'
  end

  test 'comment reply depth limit should work' do
    proposal = create(:proposal)
    attrs = attributes_for(:comment)

    limit = Rails.configuration.proposals['comment_max_depth'].to_i

    parent_comment = proposal.comment
    limit.times do
      ok, parent_comment = Comment.comment(
        proposal.user,
        parent_comment,
        attrs
      )

      assert_equal :ok, ok,
                   'should work while limit is not reached'
    end

    maximum_comment_depth, = Comment.comment(
      proposal.user,
      parent_comment,
      attrs
    )

    assert_equal :maximum_comment_depth, maximum_comment_depth,
                 'should fail if limit is reached'
  end

  test 'delete comment should work' do
    proposal = create(:proposal_with_comments)
    comment = proposal.comment.descendants.all.sample
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

  test 'liking a comment should work' do
    comment = create(:comment)
    user = create(:user)

    ok, liked_comment = Comment.like(user, comment)

    assert_equal :ok, ok,
                 'should work'
    assert_equal 1, liked_comment.likes,
                 'should update likes'

    already_liked, = Comment.like(user, comment)

    assert_equal :already_liked, already_liked,
                 'should not allow to re-like'

    other_user = create(:user)

    ok, still_liked_comment = Comment.like(other_user, comment)

    assert_equal :ok, ok,
                 'should work with other users'
    assert_equal 2, still_liked_comment.likes,
                 'should update likes once more'
  end

  test 'disliking a comment should work' do
    like = create(:comment_like)

    ok, unliked_comment = Comment.unlike(like.user, like.comment)

    assert_equal :ok, ok,
                 'should work'
    assert_equal 0, unliked_comment.likes,
                 'should be unliked'

    not_liked, = Comment.unlike(like.user, like.comment)

    assert_equal :not_liked, not_liked,
                 'should not allow to unlike without liking again'

    other_like = create(:comment_like, comment: like.comment)

    ok, still_disliked_comment = Comment.unlike(
      other_like.user,
      other_like.comment
    )

    assert_equal :ok, ok,
                 'should work'
    assert_equal 0, still_disliked_comment.likes,
                 'should be still unliked'
  end

  test 'comment like should always be updated' do
    comment = create(:comment)

    assert_equal 0, comment.likes,
                 'should have no likes'

    10.times do
      if comment.likes.zero?
        user = create(:user)

        ok, updated_comment = Comment.like(user, comment)
      else
        case %i[like unlike].sample
        when :like
          user = create(:user)

          ok, updated_comment = Comment.like(user, comment)
        when :unlike
          like = CommentLike.all.sample

          ok, updated_comment = Comment.unlike(like.user, comment)
        end
      end

      assert_equal :ok, ok,
                   'should always work'

      comment = updated_comment
    end

    assert_equal CommentLike.count, comment.likes,
                 'likes should be the same'
  end

  test 'concurrency should be handled with comment' do
    comment = create(:comment_with_likes, like_count: 5)
    current_likes = comment.likes
    workers = Random.rand(5..10)

    (1..workers)
      .map { |_| create(:user) }
      .map { |user| Thread.new { Comment.like(user, comment) } }
      .map(&:join)

    assert_equal current_likes + workers, comment.reload.likes,
                 'likes should handle concurrency properly'

    current_likes = comment.likes

    disliking_users = CommentLike
                      .all
                      .sample(Random.rand(1..current_likes))
                      .map(&:user)

    disliking_users
      .map { |user| Thread.new { Comment.unlike(user, comment) } }
      .map(&:join)

    assert_equal current_likes - disliking_users.size, comment.reload.likes,
                 'unlikes should handle concurrency properly'
  end

  test 'banned users cannot comment' do
    proposal = create(:proposal_with_comments)
    comment = proposal.comment.descendants.all.sample
    user = create(:user, is_banned: true)
    attrs = attributes_for(:comment)

    unauthorized_action, = Comment.comment(user, comment, attrs)

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow banned user to comment'
  end

  test 'ban comment should work' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: false)

    ok, banned_comment = Comment.ban(forum_admin, comment)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Comment, banned_comment,
                   'result should be a comment'
    assert banned_comment.discarded?
    assert banned_comment.is_banned,
           'comment should be banned'

    comment_already_banned, = Comment.ban(forum_admin, banned_comment)

    assert_equal :comment_already_banned, comment_already_banned,
                 'should not allow comments to be banned again'
  end

  test 'ban comment should fail safely' do
    unauthorized_action, = Comment.ban(create(:user), create(:comment))

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow normal users to ban comments'
  end

  test 'unban comment should work' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: true)

    ok, unbanned_comment = Comment.unban(forum_admin, comment)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Comment, unbanned_comment,
                   'result should be a comment'
    refute unbanned_comment.discarded?
    refute unbanned_comment.is_banned,
           'comment should be unbanned'

    comment_already_unbanned, = Comment.unban(forum_admin, unbanned_comment)

    assert_equal :comment_already_unbanned, comment_already_unbanned,
                 'should not allow comments to be unbanned again'
  end

  test 'unban comment should fail safely' do
    unauthorized_action, = Comment.unban(create(:user), create(:comment, is_banned: true))

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow normal users to unban comments'
  end

  test 'banning and deleting a comment should not be allowed' do
    forum_admin = create(:forum_admin_user)
    comment = create(:comment, is_banned: false)

    _ok, deleted_comment = Comment.delete(comment.user, comment)

    unauthorized_action, = Comment.ban(forum_admin, deleted_comment)

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow deleted comment to be banned'

    comment = create(:comment, is_banned: false)
    _ok, banned_comment = Comment.ban(forum_admin, comment)

    unauthorized_action, = Comment.delete(banned_comment.user, banned_comment)

    assert_equal :unauthorized_action, unauthorized_action,
                 'should not allow banned comment to be deleted'
  end
end
