# frozen_string_literal: true

module Types
  module Proposal
    class VotingRoundType < Types::Base::BaseObject
      description 'Voting rounds for proposal voting'

      field :total_voter_stake, String,
            null: false,
            description: 'The total number of stake for this round'
      field :total_voter_count, String,
            null: false,
            description: 'The total number of voters for this round'
      field :yes, String,
            null: false,
            description: 'Stacked DGXs that were voted voted yes'
      field :no, String,
            null: false,
            description: 'Stacked DGXs that were voted voted no'
      field :voting_deadline, String,
            null: true,
            description: 'Draft voting stage deadline'
      field :commit_deadline, String,
            null: true,
            description: 'Commit stage deadline'
      field :reveal_deadline, String,
            null: true,
            description: 'Reveal stage deadline'
    end
  end
end
