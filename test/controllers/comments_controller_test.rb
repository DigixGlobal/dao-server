# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'liking a comment should work' do
    key = Eth::Key.new
    comment = create(:comment)
    create(:user, address: key.address)

    auth_headers = auth_headers(key)

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
    key = Eth::Key.new
    like = create(:comment_like, user: create(:user, address: key.address))

    auth_headers = auth_headers(key)

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
