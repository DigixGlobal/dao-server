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

  test 'replying to a comment proposal should work' do
    key = Eth::Key.new
    create(:user, address: key.address)
    comment = create(:proposal_with_comments).comments.sample
    params = attributes_for(:proposal_comment)

    auth_headers = auth_headers(key)

    post comment_path(comment.id),
         params: params,
         headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'id', @response.body,
                 'response should contain id'

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
    key = Eth::Key.new
    user = create(:user, address: key.address)
    proposal = create(:proposal_with_comments)
    comment = create(:comment, proposal: proposal, user: user)

    auth_headers = auth_headers(key)

    delete comment_path(comment.id),
           headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'discarded', @response.body,
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

    delete comment_path(comment.id)

    assert_response :unauthorized,
                    'should fail without headers'
  end

  test 'find proposal should work' do
    key = Eth::Key.new
    user = create(:user, address: key.address)
    proposal = create(:proposal_with_comments, user: user)

    auth_headers = auth_headers(key)

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
    key = Eth::Key.new
    user = create(:user, address: key.address)
    proposal = create(:proposal_with_comments, user: user)

    auth_headers = auth_headers(key)

    get proposal_path(proposal.id),
        headers: auth_headers

    assert_response :success,
                    'should work'
    assert_match 'replies', @response.body,
                 'response should contain replies'
  end
end
