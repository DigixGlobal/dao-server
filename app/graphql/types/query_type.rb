# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :all_proposals, [ProposalType],
          null: false,
          description: 'Proposals'
    def all_proposals
      Proposal.all
    end
  end
end
