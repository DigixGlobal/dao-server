# frozen_string_literal: true

module Types
  module WatchedTransaction
    class WatchedTransactionType < Types::Base::BaseObject
      description 'Transactions that are being watched in the blockchain'

      field :id, ID,
            null: false,
            description: 'UUID of the watched transaction'

      field :user, Types::User::UserType,
            null: false,
            description: 'Signer of the transaction'

      field :transaction_object, GraphQL::Types::JSON,
            null: false,
            description: 'The JSONified transaction data object'
    end
  end
end
