# frozen_string_literal: true

module Types
  class ProposalType < Types::BaseObject
    description 'DAO proposals/projects to be voted and funded for'

    # NOTE: Should be revisited when displayName is integrated to proposal list
    field :proposal_id, String,
          null: false,
          description: 'Eth contract address of the proposal'
    field :stage, StageType,
          null: false,
          description: 'Stage/phase the proposal is in'
    field :title, String,
          null: false,
          description: "Proposal's title"
    field :description, String,
          null: false,
          description: "Proposal's short description"
    field :details, String,
          null: false,
          description: "Proposal's longer description or details"
    field :total_funding, String,
          null: false,
          description: 'Total funding for the proposal'
    field :likes, Integer,
          null: false,
          description: 'Number of user who liked this proposal'
    field :liked, Boolean,
          null: false,
          description: 'A flag to indicate if the current user liked this proposal'
    field :created_at, GraphQL::Types::ISO8601DateTime,
          null: false,
          description: 'Date when the proposal was published'

    field :comment_id, String,
          null: false,
          description: 'Root comment id of the proposal'
    field :proposer, UserType,
          null: false,
          description: 'Publisher of this proposal'
    field :voting_stage, VotingStageType,
          null: true,
          description: 'Current voting stage of this proposal'
    field :current_voting_round, VotingRoundType,
          null: true,
          description: 'Current voting round for this proposal'
    field :milestones, [MilestoneType],
          null: false,
          description: 'Milestones for this proposal'

    def self.accessible?(context)
      super && context.fetch(:current_user, nil)
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end
  end
end
