# frozen_string_literal: true

module Types
  module Value
    class IndustryType < Types::Base::BaseObject
      description 'Employment industry for KYC'

      field :value, String,
            null: false,
            description: 'Value of the industry'
      field :name, String,
            null: false,
            description: 'Name of the industry'
    end
  end
end
