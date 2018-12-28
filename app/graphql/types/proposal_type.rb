# frozen_string_literal: true

module Types
  class ProposalType < Types::BaseObject
    implements [LikeableType]
    description 'DAO proposals/projects to be voted and funded for'

    field :proposal_id, String,
          null: false,
          description: 'Proposal address'
    field :stage, StageType,
          null: false,
          description: 'Stage/phase the proposal is in'

    field :likes, Integer,
          null: false,
          description: 'Number of user who liked this proposal'
    field :liked, Boolean,
          null: false,
          description: 'A flag to indicate if the current user liked this proposal'

    field :created_at, GraphQL::Types::ISO8601DateTime,
          null: false,
          description: 'Date when the proposal was published'
    field :updated_at, GraphQL::Types::ISO8601DateTime,
          null: false,
          description: 'Date when the proposal was last updated'
  end
end
