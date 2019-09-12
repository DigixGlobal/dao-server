# frozen_string_literal: true

module Mutations
  class WatchTransactionMutation < Types::Base::BaseMutation
    description 'Given a transaction, save it to the database to be resent'

    argument :transaction_hash, String,
             required: true,
             description: 'Transaction hash'
    argument :transaction_object, Types::Scalar::JSONObject,
             required: true,
             description: 'The JSONified transaction data object'
    argument :signed_transaction, String,
             required: true,
             description: 'Signed transaction in HEX format'

    field :watched_transaction, Types::WatchedTransaction::WatchedTransactionType,
          null: true,
          description: 'Newly created transaction'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Invalid transaction object
          EOS

    def resolve(transaction_hash:, transaction_object:, signed_transaction:)
      key = :watched_transaction

      attrs = {
        txhash: transaction_hash,
        transaction_object: transaction_object,
        signed_transaction: signed_transaction
      }

      result, tx_or_errors = WatchingTransaction.watch(
        context.fetch(:current_user),
        attrs
      )

      case result
      when :invalid_data
        model_errors(key, tx_or_errors)
      when :ok
        model_result(key, tx_or_errors)
      end
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
