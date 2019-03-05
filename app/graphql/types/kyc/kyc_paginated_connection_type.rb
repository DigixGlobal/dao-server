# frozen_string_literal: true

module Types
  module Kyc
    class KycPaginatedConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(Types::Kyc::KycEdgeType)

      description <<~EOS
        Page-based pagination container for KYCs.
         Note: AVOID USING `pageInfo` since it does nothing and not easily customized at the moment.
         Instead, use `hasNextPage` and `hasPreviousPage` from this object.
      EOS

      field :total_count, Integer,
            null: false,
            description: 'Total number of records for this collection'
      field :total_page, Integer,
            null: false,
            description: 'Total number of pages for this collection relative to page size'
      field :has_next_page, Boolean,
            null: false,
            description: 'When paginating forwards, are there more items?'
      field :has_previous_page, Boolean,
            null: false,
            description: 'When backwards forwards, are there more items?'

      def total_count
        object.arguments[:total_count]
      end

      def total_page
        object.arguments[:total_page]
      end

      def has_previous_page
        object.arguments[:has_previous_page]
      end

      def has_next_page
        object.arguments[:has_next_page]
      end
    end
  end
end
