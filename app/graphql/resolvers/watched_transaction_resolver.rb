# frozen_string_literal: true

module Resolvers
  class WatchedTransactionResolver < Resolvers::Base
    type Types::WatchedTransaction::WatchedTransactionType, null: true

    argument :txhash, String,
             required: true,
             description: 'Find the last watched transaction in the group with that txhash'

    def resolve(txhash:)
      unless (tx = WatchingTransaction.find_by(txhash: txhash))
        return nil
      end

      WatchingTransaction.where(group_id: tx.group_id).order('created_at ASC').last
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
