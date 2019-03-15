# frozen_string_literal: true

module Types
  module Enum
    class TransactionStatusEnum < Types::Base::BaseEnum
      description 'Transaction status'

      value 'CONFIRMED', 'Transaction confirmed in the blockchain',
            value: 'confirmed'
      value 'FAILED', 'Transaction failed in the blockchain',
            value: 'failed'
      value 'SEEN', 'Transaction being monitored for result in the blockchain',
            value: 'seen'
      value 'PENDING', 'Transaction status unknown or pending in the blockchain',
            value: 'pending'
    end
  end
end
