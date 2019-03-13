# frozen_string_literal: true

module Subscriptions
  class TransactionUpdated < Subscriptions::BaseSubscription
    description 'Changes in transactions'

    argument :proposal_id, String,
             required: false,
             description: 'Filter transaction updates by `Proposal.proposalId`'

    field :transaction, Types::Transaction::TransactionType,
          null: false

    def subscribe
      :no_response
    end

    def update(proposal_id: nil)
      return :no_update if proposal_id && (object.project != proposal_id)

      { transaction: object }
    end
  end
end
