# frozen_string_literal: true

require 'test_helper'

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create new proposal should work' do
    payload = attributes_for(:info_proposal)
    create(:user, address: payload.fetch(:proposer))
    path = proposals_create_path

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
         params: { payload: payload }.to_json

    assert_response :forbidden,
                    'should fail without authorization'
  end

  test 'comment on proposal should work' do
    key = Eth::Key.new
    proposal = create(:proposal, user: create(:user, address: key.address))
    params = attributes_for(:proposal_comment)

    auth_headers = auth_headers(key)

    post proposal_comments_path(proposal.id),
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

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

  test 'find proposal should work' do
    key = Eth::Key.new
    user = create(:user, address: key.address)
    proposal = create(:proposal, user: user)
    30.times do
      create(:comment, proposal: proposal, stage: generate(:proposal_stage))
    end

    auth_headers = auth_headers(key)

    get proposal_detail_path(proposal.id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

    get proposal_detail_path('NON_EXISTENT_ID'),
        headers: auth_headers

    assert_response :not_found,
                    'should not find proposal'
  end
end
