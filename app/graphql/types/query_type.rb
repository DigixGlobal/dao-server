# frozen_string_literal: true

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
      Proposal.select_user_proposals(
        context[:current_user],
        attrs
      )
    end
  end
end
