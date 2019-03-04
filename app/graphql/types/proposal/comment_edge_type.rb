# frozen_string_literal: true

module Types
  module Proposal
    class CommentEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(Types::Proposal::CommentType)
    end
  end
end
