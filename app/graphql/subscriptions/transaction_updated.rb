# frozen_string_literal: true

module Subscriptions
  class TransactionUpdated < Subscriptions::BaseSubscription
    description 'Changes in transactions'

    argument :proposal_id, String,
             required: false,
             description: 'Filter transaction updates by `Proposal.proposalId`'

    field :transaction, Types::Transaction::TransactionType,
          null: false

    def subscribe(proposal_id: nil)
      context[:proposal_id] = proposal_id

      :no_response
    end

    def update(*)
      subscription_id = context[:proposal_id]
      transaction = object[:transaction]
      proposal_id = object[:project]

      return :no_update unless transaction[:user_id] == context[:current_user_id]
      return :no_update if proposal_id && (subscription_id != proposal_id)

      { transaction: transaction }
    end
  end
end
