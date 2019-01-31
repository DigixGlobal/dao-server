# frozen_string_literal: true

module Resolvers
  class ProposalsResolver < Resolvers::Base
    type [Types::ProposalType], null: false

    argument :proposal_ids, [String],
             required: false,
             description: 'Filter proposals by a list of proposal id addresses'
    argument :stage, Types::StageType,
             required: false,
             description: 'Filter proposals by its stage/phase'
    argument :liked, Boolean,
             required: false,
             description: 'Filter proposals if it is liked or not by the current user'
    argument :sort_by, Types::SortByType,
             required: false,
             default_value: 'desc',
             description: 'Sorting options for the proposals'

    def resolve(**attrs)
      dao_proposals = Proposal.select_user_proposals(
        context[:current_user],
        attrs
      )

      result, info_proposals_or_error = InfoApi.list_proposals

      raise GraphQL::ExecutionError, 'Network failure' unless result == :ok

      zip_by_keys(dao_proposals, info_proposals_or_error, 'proposal_id')
        .map do |merged|
          dao_proposal, info_proposal = merged

          dao_proposal
            .attributes
            .merge(info_proposal.except('stage'))
            .deep_merge(
              'proposer' => dao_proposal.user,
              'current_voting_round' => info_proposal.fetch('draft_voting', nil)
            )
        end
    end

    private

    def zip_by_keys(left, right, key)
      return [] if left.nil? || left.empty?
      return left if right.nil? || right.empty?

      right_hash = Hash[right.map { |item| [item[key], item.to_h] }]
      left.map { |item| [item, right_hash.fetch(item[key], nil)] }
    end
  end
end
