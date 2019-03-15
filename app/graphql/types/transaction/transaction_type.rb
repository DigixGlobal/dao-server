# frozen_string_literal: true

module Types
  module Transaction
    class TransactionType < Types::Base::BaseObject
      description 'Transactions that are being watched in the blockchain'

      field :id, ID,
            null: false,
            description: 'Transaction ID'
      field :title, String,
            null: false,
            description: 'Transaction title'
      field :txhash, String,
            null: false,
            description: 'Transaction hash address'
      field :status, Types::Enum::TransactionStatusEnum,
            null: false,
            description: 'Transaction status in the blockchain'
      field :block_number, Integer,
            null: true,
            description: <<~EOS
              Transaction block number in the block chain.

              Has value when status is `SEEN`.
            EOS
      field :user, Types::User::UserType,
            null: false,
            description: 'User who triggered this transaction.'
      field :transaction_type, String,
            null: true,
            description: <<~EOS
              Transaction application type.

              Has value when this is related to a proposal.
            EOS
      field :project, String,
            null: true,
            description: <<~EOS
              Transaction application project.

              Has value when this is related to a proposal.
            EOS

      field :created_at, GraphQL::Types::ISO8601DateTime,
            null: false,
            description: 'Date when the proposal was published'

      def status
        object.status.nil? ? 'pending' : object.status
      end
    end
  end
end
