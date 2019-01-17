# frozen_string_literal: true

module Resolvers
  class CountriesResolver < Resolvers::Base
    type [Types::CountryType], null: false

    argument :blocked, Boolean,
             required: false,
             default_value: false,
             description: <<~EOS
               Filter countries if they are blocked.

               By default, this returns the usable countries for the frontend.
             EOS

    def resolve(blocked: true)
      countries = JSON.parse(File.read(File.join(Rails.root, 'config', 'countries.json')))

      countries.select { |country| country['blocked'] == blocked }
    end
  end
end
