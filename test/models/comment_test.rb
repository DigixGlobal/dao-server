# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup :database_fixture

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
end
