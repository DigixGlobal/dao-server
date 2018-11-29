# frozen_string_literal: true

require 'test_helper'

class ProposalTest < ActiveSupport::TestCase
  setup :database_fixture

  test 'create new proposal should work' do
    user = create(:user)
    params = attributes_for(
      :proposal,
      id: generate(:proposal_id),
      proposer: user.address
    )

    ok, proposal = Proposal.create_proposal(params)

    assert_equal :ok, ok,
                 'should work'
    assert_equal params.fetch(:id), proposal.id,
                 'proposal should respect the id'
    assert_equal :idea, proposal.stage.to_sym,
                 'proposal should be at the idea stage'

    user_not_found, = Proposal.create_proposal(
      params.merge(proposer: 'NON_EXISTENT')
    )

    assert_equal :invalid_data, user_not_found,
                 'user should exist when creating proposals'

    invalid_data, = Proposal.create_proposal(params)

    assert_equal :invalid_data, invalid_data,
                 'adding the same proposal should fail'

    invalid_data, = Proposal.create_proposal({})

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'
  end

  test 'comment on post should work' do
    proposal = create(:proposal)
    user = proposal.user
    attrs = attributes_for(:comment)

    ok, comment = Proposal.comment(proposal, user, attrs)

    assert_equal :ok, ok,
                 'should work'
    assert_kind_of Comment, comment,
                   'result should be a comment'
    assert_equal proposal.stage, comment.stage,
                 'comment and proposal should have the same stage/status'

    ok, other_comment = Proposal.comment(proposal, user, attrs)

    assert_equal :ok, ok,
                 'making the same comment should work'
    assert_not_equal comment.id, other_comment.id,
                     'other comments should be different'

    invalid_data, = Proposal.comment(proposal, user, {})

    assert_equal :invalid_data, invalid_data,
                 'should fail with empty data'
  end
end
