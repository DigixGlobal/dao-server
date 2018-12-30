# frozen_string_literal: true

require 'info_api'

module Types
  class SortByType < Types::BaseEnum
    value 'DESC', 'Sort in descending creation time',
          value: 'desc'
    value 'ASC', 'Sort in ascending creation time',
          value: 'asc'
  end

  class QueryType < Types::BaseObject
    field :search_proposals, [ProposalType],
          null: false,
          description: 'Search for proposals/projects' do
      argument :proposal_ids, [String],
               required: false,
               description: 'Filter proposals by a list of proposal id addresses'
      argument :stage, StageType,
               required: false,
               description: 'Filter proposals by its stage/phase'
      argument :liked, Boolean,
               required: false,
               description: 'Filter proposals if it is liked or not by the current user'
      argument :sort_by, SortByType,
               required: false,
               default_value: 'desc',
               description: 'Sorting options for the proposals'
    end

    field :search_comments, [CommentType],
          null: false,
          description: 'Proposals' do
      argument :stage, StageType,
               required: false,
               description: 'Filter proposals by its stage/phase'
      argument :liked, Boolean,
               required: false,
               description: 'Filter proposals if it is liked or not by the current user'
      argument :sort_by, SortByType,
               required: false,
               default_value: 'desc',
               description: 'Sorting options for the proposals'
    end

    def search_proposals(**attrs)
      dao_proposals = Proposal.select_user_proposals(
        context[:current_user],
        attrs
      )

      result, info_proposals_or_error = InfoApi.list_proposals

      raise GraphQL::ExecutionError, 'Network failure' unless result == :ok

      merge_by_keys(dao_proposals, info_proposals_or_error, :proposal_id)
    end

    private

    def merge_by_keys(left, right, key)
      return [] if left.nil? || left.empty?
      return left if right.nil? || right.empty?

      right_hash = Hash[right.map { |item| [item[key], item] }]
      left.map { |item| item.merge(right_hash.fetch(item[key], {})) }
    end
  end
end
