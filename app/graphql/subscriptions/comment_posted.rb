# frozen_string_literal: true

module Subscriptions
  class CommentPosted < Subscriptions::BaseSubscription
    description 'Payload for any comment posted'

    field :comment, Types::Proposal::CommentType,
          null: false

    def subscribe
      :no_response
    end

    def update
      { comment: object }
    end
  end
end
