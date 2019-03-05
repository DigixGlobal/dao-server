# frozen_string_literal: true

module Types
  module Enum
    class EmploymentStatusEnum < Types::Base::BaseEnum
      description "Customer's employment status"

      value 'EMPLOYED', 'Works for a company',
            value: 'employed'
      value 'SELF_EMPLOYED', 'Works as a freelancer',
            value: 'self_employed'
      value 'UNEMPLOYED', "Doesn't work for money",
            value: 'unemployed'
    end
  end
end
