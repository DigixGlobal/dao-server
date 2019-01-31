# frozen_string_literal: true

GRAPHQL_PRIMARY_PARAM = 'query'

ActionDispatch::Request.parameter_parsers[:json] = ->(raw_post) {
  data = ActiveSupport::JSON.decode(raw_post)
  data = { _json: data } unless data.is_a?(Hash)

  if data.key?(GRAPHQL_PRIMARY_PARAM)
    data
  else
    data.deep_transform_keys!(&:underscore)
  end
}
