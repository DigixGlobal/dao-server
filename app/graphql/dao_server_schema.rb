class DaoServerSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
