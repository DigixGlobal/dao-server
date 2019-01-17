# frozen_string_literal: true

require 'test_helper'

class ViewerQueryTest < ActiveSupport::TestCase
  QUERY = <<~EOS
    query($stage: Stage) {
      proposals(stage: $stage) {
        proposalId
        stage
        title
        description
        details
        liked
        likes
        proposer {
          displayName
        }
        votingStage
        currentVotingRound {
          totalVoterCount
          totalVoterStake
          yes
          no
          commitDeadline
          revealDeadline
          votingDeadline
        }
        milestones {
          title
          description
        }
      }
    }
  EOS

  test 'proposals query should work' do
    stub_request(:any, %r{proposals/all})
      .to_return(body: {
        result: create_list(:proposal, Random.rand(1..5))
          .map { |proposal| attributes_for(:info_proposal, proposal_id: proposal.proposal_id) }
      }.to_json)

    user = create(:user)
    _stage = generate(:proposal_stage)

    result = DaoServerSchema.execute(
      QUERY,
      context: { current_user: user },
      variables: {}
    )

    assert_nil result['errors'],
               'should work and have no errors'

    assert_not_empty result['data']['proposals'],
                     'proposals should work'
  end
end
