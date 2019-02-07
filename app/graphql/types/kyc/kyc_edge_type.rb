# frozen_string_literal: true

module Types
  module Kyc
    class KycEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(KycType)
    end
  end
end
