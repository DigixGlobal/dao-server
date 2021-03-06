# frozen_string_literal: true

module Types
  module Value
    class IncomeRangeType < Types::Base::BaseObject
      description 'Employment income ranges for KYC'

      field :value, String,
            null: false,
            description: 'Value of the income range'
      field :range, String,
            null: false,
            description: 'Descriptive value of the income range'
    end
  end
end
