# frozen_string_literal: true

module Resolvers
  class SearchTransactionsResolver < Resolvers::Base
    type Types::Transaction::TransactionType.connection_type,
         null: false

    argument :proposal_id, String,
             required: false,
             description: 'Filter transaction updates by `Proposal.proposalId`'
    argument :status, Types::Enum::TransactionStatusEnum,
             required: false,
             description: 'Filter transactions by their status.'

    def resolve(status: nil, proposal_id: nil)
      current_user = context.fetch(:current_user)
      query = current_user.transactions

      query = query.where(transaction_type: 1) if status == 'pending'
      query = query.where(project: proposal_id) if proposal_id

      query.order('created_at DESC')
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
