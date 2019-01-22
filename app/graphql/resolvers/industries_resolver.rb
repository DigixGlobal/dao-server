# frozen_string_literal: true

module Resolvers
  class IndustriesResolver < Resolvers::Base
    type [Types::IndustryType], null: false

    def resolve
      Rails.configuration.industries
    end
  end
end
