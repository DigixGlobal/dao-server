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
  end
end
