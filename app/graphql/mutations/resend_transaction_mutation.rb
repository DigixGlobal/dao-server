# frozen_string_literal: true

module Mutations
  class ResendTransactionMutation < Types::Base::BaseMutation
    description 'Given an old transaction, resend it with new parameters or gas prices'

    argument :id, ID,
             required: true,
             description: 'ID of the transaction to be resent'
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
            - Previous transaction not found
            - Unauthorized action
            - Nonce is not the same as the previous
          EOS

    def resolve(id:, transaction_hash:, transaction_object:, signed_transaction:)
      key = :watched_transaction

      unless (old = WatchingTransaction.find_by(id: id))
        return form_error(key, 'transaction_object', 'Previous transaction not found')
      end

      attrs = {
        txhash: transaction_hash,
        transaction_object: transaction_object,
        signed_transaction: signed_transaction
      }

      result, tx_or_errors = WatchingTransaction.resend(
        context.fetch(:current_user, nil),
        old,
        attrs
      )

      case result
      when :unauthorized_action
        form_error(key, 'id', 'Unauthorized action')
      when :invalid_nonce
        form_error(key, 'transaction_object', 'Nonce is not the same as the previous')
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
