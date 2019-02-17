# frozen_string_literal: true

require 'info_api'

module Types
  class QueryType < Types::Base::BaseObject
    field :current_user, Types::User::AuthorizedUserType,
          null: true,
          description: <<~EOS
            Get the current user's information
          EOS
    def current_user
      context[:current_user]
    end

    field :search_kycs,
          resolver: Resolvers::SearchKycsResolver,
          connection: false,
          description: <<~EOS
            Search for KYCs, pending or all

            Role: KYC Officer
          EOS

    field :user,
          resolver: Resolvers::UserResolver,
          description: <<~EOS
            Find a specific user.

            Role: KYC Officer
          EOS

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
    field :rejection_reasons,
          resolver: Resolvers::RejectionReasonsResolver,
          description: 'List of rejection reasons for KYC rejection'
  end
end
