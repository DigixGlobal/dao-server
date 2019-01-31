# frozen_string_literal: true

namespace :graphql do
  desc 'Dao Server Schema'
  task dump_schema: :environment do
    schema_defn = DaoServerSchema.to_definition
    schema_path = 'app/graphql/schema.graphql'
    File.write(Rails.root.join(schema_path), schema_defn)
    puts "Updated #{schema_path}"
  end
end
