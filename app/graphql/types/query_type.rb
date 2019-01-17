# frozen_string_literal: true

require 'info_api'

module Types
  class QueryType < Types::BaseObject
    field :viewer, AuthorizedUserType,
          null: false,
          description: "Get the current user's information"
    def viewer
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
