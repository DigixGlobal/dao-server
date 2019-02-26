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
          description: 'A KYC was updated',
          subscription_scope: :current_user_id
  end
end
