# frozen_string_literal: true

module Subscriptions
  class CommentUpdated < Subscriptions::BaseSubscription
    description 'Changes in comments'

    field :comment, Types::Proposal::UpdatedCommentType,
          null: false

    def subscribe
      :no_response
    end

    def update
      { comment: object }
    end
  end
end
