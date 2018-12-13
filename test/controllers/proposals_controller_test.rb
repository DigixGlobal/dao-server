# frozen_string_literal: true

require 'test_helper'

class ProposalsControllerTest < ActionDispatch::IntegrationTest
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

  test 'find proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments, user: user)

    get proposal_path(proposal.proposal_id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'
    assert_match 'liked', @response.body,
                 'response should contain liked'

    get proposal_path('NON_EXISTENT_ID'),
        headers: auth_headers

    assert_response :not_found,
                    'should not find proposal'
  end

  test 'liking a proposal should work' do
    _user, auth_headers, _key = create_auth_user
    proposal = create(:proposal)

    post proposal_likes_path(proposal.proposal_id),
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'
    assert_match 'liked', @response.body,
                 'response should contain liked'

    post proposal_likes_path('NON_EXISTENT_ID'),
         headers: auth_headers

    assert_response :not_found,
                    'should fail to find proposal'

    post proposal_likes_path(proposal.proposal_id),
         headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'already_liked', @response.body,
                 'response should contain already liked status'
  end

  test 'unliking a proposal should work' do
    user, auth_headers, _key = create_auth_user
    like = create(:proposal_like, user: user)
    proposal = like.proposal

    delete proposal_likes_path(proposal.proposal_id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'
    assert_match 'liked', @response.body,
                 'response should contain liked'

    delete proposal_likes_path('NON_EXISTENT_ID'),
           headers: auth_headers

    assert_response :not_found,
                    'should fail to find proposal'

    delete proposal_likes_path(proposal.proposal_id),
           headers: auth_headers

    assert_response :success,
                    'should fail if repeated'
    assert_match 'not_liked', @response.body,
                 'response should contain not liked status'
  end
end
