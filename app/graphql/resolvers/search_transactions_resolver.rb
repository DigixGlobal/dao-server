# frozen_string_literal: true

module Resolvers
  class SearchTransactionsResolver < Resolvers::Base
    type Types::Transaction::TransactionType.connection_type,
         null: false

    argument :status, Types::Enum::TransactionStatusEnum,
             required: false,
             description: 'Filter transactions by their status.'

    def resolve(status: nil)
      current_user = context.fetch(:current_user)
      query = current_user.transactions

      query = query.where(transaction_type: 1) if status == 'pending'

      query.order('created_at DESC')
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
