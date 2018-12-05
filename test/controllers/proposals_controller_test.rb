# frozen_string_literal: true

require 'test_helper'

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create new proposal should work' do
    payload = attributes_for(:info_proposal)
    create(:user, address: payload.fetch(:proposer))
    path = proposals_path

    post path,
         params: { payload: payload }.to_json,
         headers: info_server_headers(
           'POST',
           path,
           payload
         )

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post path,
         params: { payload: nil }.to_json,
         headers: info_server_headers(
           'POST',
           path,
           nil
         )

    assert_response :success,
                    'should fail with empty data'
    assert_match 'error', @response.body,
                 'response should be ann error'

    post path,
         params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without authorization'
  end

  test 'comment on proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal, user: user)
    params = attributes_for(:proposal_comment)

    post proposal_comments_path(proposal.id),
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post proposal_comments_path(proposal.id),
         headers: auth_headers

    assert_response :forbidden,
                    'should throttle commenting'

    sleep(3.seconds)

    post proposal_comments_path(proposal.id),
         headers: auth_headers

    assert_response :success,
                    'should fail with empty data'
    assert_match 'error', @response.body,
                 'response should be an error'

    post proposal_comments_path('NON_EXISTENT_ID'),
         params: params,
         headers: auth_headers

    assert_response :not_found,
                    'should not find proposal'

    post proposal_comments_path(proposal.id),
         params: params

    assert_response :unauthorized,
                    'should fail without authorization'
  end

  test 'replying to a comment proposal should work' do
    _user, auth_headers, _key = create_auth_user
    comment = create(:proposal_with_comments).comments.sample
    params = attributes_for(:proposal_comment)

    post comment_path(comment.id),
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post comment_path(comment.id),
         headers: auth_headers

    assert_response :forbidden,
                    'should throttle commenting'

    sleep(3.seconds)

    post comment_path(comment.id),
         headers: auth_headers

    assert_response :success,
                    'should fail with empty data'
    assert_match 'error', @response.body,
                 'response should be an error'

    post comment_path('NON_EXISTENT_ID'),
         params: params,
         headers: auth_headers

    assert_response :not_found,
                    'should not find comment'

    post comment_path(comment.id),
         params: params

    assert_response :unauthorized,
                    'should fail without authorization'
  end

  test 'deleting a comment should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments)
    comment = create(:comment, proposal: proposal, user: user)

    delete comment_path(comment.id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'stage', @response.body,
                 'response be ok'

    delete comment_path(comment.id),
           headers: auth_headers

    assert_response :not_found,
                    'should fail with deleted comment'

    other_comment = create(:comment, proposal: proposal)

    delete comment_path(other_comment.id),
           headers: auth_headers

    assert_response :forbidden,
                    'should not allow to delete other comment'

    delete comment_path('NON_EXISTENT_ID'),
           headers: auth_headers

    assert_response :not_found,
                    'should not find the comment'

    delete comment_path(comment.id)

    assert_response :unauthorized,
                    'should fail without headers'
  end

  test 'find proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments, user: user)

    get proposal_path(proposal.id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    get proposal_path('NON_EXISTENT_ID'),
        headers: auth_headers

    assert_response :not_found,
                    'should not find proposal'
  end

  test 'find proposal threads should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments, user: user)

    get proposal_path(proposal.id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'replies', @response.body,
                 'response should contain replies'
  end

  test 'liking a proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal)

    post proposal_likes_path(proposal.id),
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    post proposal_likes_path('NON_EXISTENT_ID'),
         headers: auth_headers

    assert_response :not_found,
                    'should fail to find proposal'

    post proposal_likes_path(proposal.id),
         headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'already_liked', @response.body,
                 'response should contain already liked status'
  end

  test 'unliking a proposal should work' do
    user, auth_headers, _key = create_auth_user
    like = create(:proposal_like, user: user)

    delete proposal_likes_path(like.proposal_id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    delete proposal_likes_path('NON_EXISTENT_ID'),
           headers: auth_headers

    assert_response :not_found,
                    'should fail to find proposal'

    delete proposal_likes_path(like.proposal_id),
           headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'not_liked', @response.body,
                 'response should contain not liked status'
  end
end
