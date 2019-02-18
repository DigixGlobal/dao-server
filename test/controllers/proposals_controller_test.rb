# frozen_string_literal: true

require 'test_helper'

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  test 'create new proposal should work' do
    payload = attributes_for(:create_proposal)
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

  test 'select proposal should work' do
    user, _auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments, user: user)
    other_proposal = create(:proposal_with_comments, user: user)
    Proposal.like(user, other_proposal)

    get proposals_path

    assert_response :success,
                    'should work'
    assert_match 'proposalId', @response.body,
                 'response should contain proposal id'
    assert_match 'liked', @response.body,
                 'response should contain liked property'

    get proposals_path,
        params: {
          proposal_ids: [proposal.proposal_id]
        }

    assert_response :success,
                    'should work with ids filter'
    assert_match 'proposalId', @response.body,
                 'response should contain proposal id'

    get proposals_path,
        params: {
          stage: proposal.stage
        }

    assert_response :success,
                    'should filter by stage'
    assert_match 'proposalId', @response.body,
                 'response should contain proposal id'

    %i[asc desc].each do |sort|
      get proposals_path,
          params: {
            sort_by: sort
          }

      assert_response :success,
                      "should sort by #{sort}"
      assert_match 'proposalId', @response.body,
                   'response should contain proposal id'
    end

    ['', 'not'].each do |liked|
      get proposals_path,
          params: {
            liked: liked
          }

      assert_response :success,
                      "should filter like by #{liked}"
      assert_match 'result', @response.body,
                   'response should contain proposal id'
    end
  end

  test 'find proposal should work' do
    user, auth_headers, _key = create_auth_user
    proposal = create(:proposal_with_comments, user: user)

    get proposal_path(proposal.proposal_id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'proposalId', @response.body,
                 'response should contain proposal id'
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
    assert_match 'proposalId', @response.body,
                 'response should contain proposal Id'
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
    assert_match 'proposalId', @response.body,
                 'response should contain proposal Id'
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
