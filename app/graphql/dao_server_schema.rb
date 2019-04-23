# frozen_string_literal: true

class DaoServerSchema < GraphQL::Schema
  use BatchLoader::GraphQL
  use GraphQL::Guard.new
  use GraphQL::Subscriptions::ActionCableSubscriptions

  subscription(Types::SubscriptionType)
  mutation(Types::MutationType)
  query(Types::QueryType)

  lazy_resolve(Types::Proposal::LazyCommentThread, :replies)
  lazy_resolve(Types::Proposal::LazyPoints, :points)

  def self.unauthorized_object(error)
    raise GraphQL::ExecutionError,
          "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end
end
