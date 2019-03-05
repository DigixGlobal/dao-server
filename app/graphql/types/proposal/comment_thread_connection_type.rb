# frozen_string_literal: true

module Types
  module Proposal
    class CommentThreadConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(Types::Proposal::CommentEdgeType)

      description <<~EOS
        Connection pagination container for comment threads.
         Note: AVOID USING `pageInfo` since it isn't implemented as with `KycConnection`.
         Instead, use only `hasNextPage` from this object.
      EOS

      field :end_cursor, String,
            null: true,
            description: 'When paginating forwards, the cursor to continue.'
      field :has_next_page, Boolean,
            null: false,
            description: 'When paginating forwards, are there more items?'

      def has_next_page
        object.arguments.fetch(:has_next_page, false)
      end

      def end_cursor
        if (cursor = object.arguments.fetch(:end_cursor, nil))
          Base64.strict_encode64(cursor.to_json)
        end
      end
    end
  end
end
