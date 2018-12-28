# frozen_string_literal: true

module Types
  class ProposalType < Types::BaseObject
    description 'DAO proposals/projects to be voted and funded for'

    field :proposal_id, String,
          null: false,
          description: 'Eth contract address of the proposal'
    field :stage, StageType,
          null: false,
          description: 'Stage/phase the proposal is in'

    field :likes, Integer,
          null: false,
          description: 'Number of user who liked this proposal'
    field :liked, Boolean,
          null: false,
          description: 'A flag to indicate if the current user liked this proposal',
          method: :user_liked

    field :created_at, GraphQL::Types::ISO8601DateTime,
          null: false,
          description: 'Date when the proposal was published'

    field :user, UserType,
          null: false,
          description: 'Publisher of this proposal'

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    def self.visible?(context)
      authorized?(nil, context)
    end

    def user_liked
      !object.proposal_like_id.nil?
    end
  end
end