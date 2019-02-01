# frozen_string_literal: true

require 'info_api'

module Types
  class QueryType < Types::BaseObject
    field :current_user, AuthorizedUserType,
          null: false,
          description: "Get the current user's information"
    def current_user
      context[:current_user]
    end

    field :proposals,
          resolver: Resolvers::ProposalsResolver,
          description: 'Search for proposals/projects'

    field :comment_threads,
          resolver: Resolvers::CommentThreadsResolver,
          description: 'Proposals'

    field :countries,
          resolver: Resolvers::CountriesResolver,
          description: 'List of countries to determine nationality for KYC'
    field :income_ranges,
          resolver: Resolvers::IncomeRangesResolver,
          description: 'List of income ranges for KYC'
    field :industries,
          resolver: Resolvers::IndustriesResolver,
          description: 'List of industries for KYC'
  end
end
