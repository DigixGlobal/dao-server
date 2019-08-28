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

    field :app_user, Types::User::AppUserType,
          resolver: Resolvers::AppUserResolver,
          description: <<~EOS
            Get the user's application status.
          EOS

    field :search_kycs,
          resolver: Resolvers::SearchKycsResolver,
          connection: false,
          description: <<~EOS
            Search for KYCs, pending or all.

            Role: KYC Officer
          EOS
    field :kyc,
          resolver: Resolvers::KycResolver,
          description: <<~EOS
            Find a KYC by id.

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
          connection: false,
          description: <<~EOS
            Search comment threads by either proposal or comment.
             See `comment.replies` for what threads are.
          EOS

    field :search_dao_users,
          resolver: Resolvers::SearchDaoUsersResolver,
          connection: true,
          description: <<~EOS
            Search for DAO users.

            For now, this uses the standard Relay connection pagination.
             This might change to default page pagination.

            Role: Forum Admin
          EOS

    field :search_transactions,
          resolver: Resolvers::SearchTransactionsResolver,
          connection: true,
          description: <<~EOS
            Search for the current user's transactions.
          EOS

    field :watched_transaction,
          resolver: Resolvers::WatchedTransactionResolver,
          description: <<~EOS
            Given a transaction txhash, find the last watched transaction in the group with that txhash.
          EOS

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
