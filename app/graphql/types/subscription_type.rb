# frozen_string_literal: true

module Types
  class SubscriptionType < GraphQL::Schema::Object
    field :comment_posted,
          subscription: Subscriptions::CommentPosted,
          description: 'A comment was posted on some project'
    field :comment_updated,
          subscription: Subscriptions::CommentUpdated,
          description: 'A comment was updated on some project'

    field :kyc_updated,
          subscription: Subscriptions::KycUpdated,
          subscription_scope: :current_user_id,
          description: <<~EOS
            A KYC was updated.

            Only updates users of their respective KYC.
          EOS

    field :transaction_updated,
          subscription: Subscriptions::TransactionUpdated,
          subscription_scope: :current_user_id,
          description: <<~EOS
            A transaction was updated.

            Only updates users who triggered the transaction.
          EOS
  end
end
