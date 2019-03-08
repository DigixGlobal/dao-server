# frozen_string_literal: true

module Subscriptions
  class TransactionUpdated < Subscriptions::BaseSubscription
    description 'Changes in transactions'

    field :transaction, Types::Transaction::TransactionType,
          null: false

    def subscribe
      :no_response
    end

    def update
      { transaction: object }
    end
  end
end
