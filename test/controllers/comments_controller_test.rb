# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'comment on proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal, user: user)
    root_comment = proposal.comment
    params = attributes_for(:proposal_comment)

    post comments_path(root_comment.id),
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post comments_path(root_comment.id),
         headers: auth_headers

    assert_response :forbidden,
                    'should throttle commenting'

    sleep(3.seconds)

    post comments_path(root_comment.id),
         headers: auth_headers

    assert_response :success,
                    'should fail with empty data'
    assert_match 'error', @response.body,
                 'response should be an error'

    post comments_path('NON_EXISTENT_ID'),
         params: params,
         headers: auth_headers

    assert_response :not_found,
                    'should not find proposal'

    post comments_path(root_comment.id),
         params: params

    assert_response :unauthorized,
                    'should fail without authorization'
  end

  test 'deleting a comment should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments)
    comment = create(:comment, parent: proposal.comment, user: user)

    delete comments_path(comment.id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'stage', @response.body,
                 'response be ok'

    delete comments_path(comment.id),
           headers: auth_headers

    assert_response :not_found,
                    'should fail with deleted comment'

    other_comment = create(:comment, parent: proposal.comment)

    delete comments_path(other_comment.id),
           headers: auth_headers

    assert_response :forbidden,
                    'should not allow to delete other comment'

    delete comments_path('NON_EXISTENT_ID'),
           headers: auth_headers

    assert_response :not_found,
                    'should not find the comment'

    delete comments_path(comment.id)

    assert_response :unauthorized,
                    'should fail without headers'
  end

  test 'selecting a comment should work' do
    _user, auth_headers, _key = create_auth_user
    comment = create(:comment)

    get comment_threads_path(comment.id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'hasMore', @response.body,
                 'response be ok'
  end

  test 'liking a comment should work' do
    _user, auth_headers, _key = create_auth_user
    comment = create(:comment)

    post comment_likes_path(comment.id),
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post comment_likes_path('NON_EXISTENT_ID'),
         headers: auth_headers

    assert_response :not_found,
                    'should fail to find comment'

    post comment_likes_path(comment.id),
         headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'already_liked', @response.body,
                 'response should contain already liked status'
  end

  test 'unliking a comment should work' do
    user, auth_headers, _key = create_auth_user
    like = create(:comment_like, user: user)

    delete comment_likes_path(like.comment_id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    delete comment_likes_path('NON_EXISTENT_ID'),
           headers: auth_headers

    assert_response :not_found,
                    'should fail to find comment'

    delete comment_likes_path(like.comment_id),
           headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'not_liked', @response.body,
                 'response should contain not liked status'
  end
end
