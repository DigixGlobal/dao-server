# frozen_string_literal: true

module Types
  module Kyc
    class KycEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(Types::Kyc::KycType)
    end
  end
end
