# frozen_string_literal: true

module Resolvers
  class RejectionReasonsResolver < Resolvers::Base
    type [Types::Value::RejectionReasonType], null: false

    def resolve
      JSON.parse(File.read(File.join(Rails.root, 'config', 'rejection_reasons.json')))
    end
  end
end
