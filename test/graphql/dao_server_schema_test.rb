# frozen_string_literal: true

require 'test_helper'

class DaoServerSchemaTest < ActiveSupport::TestCase
  test 'schema is up to date' do
    current_schema = DaoServerSchema.to_definition
    generated_schema = File.read(Rails.root.join('app/graphql/schema.graphql'))

    assert_equal current_schema, generated_schema,
                 'Update the generated schema with `bundle exec rake graphql:dump_schema`'
  end
end
