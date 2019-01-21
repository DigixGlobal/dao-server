# frozen_string_literal: true

module Types
  class EmploymentStatusEnum < Types::BaseEnum
    description "Customer's employment status"

    value 'EMPLOYED', 'Works for a company',
          value: 'employed'
    value 'SELF_EMPLOYED', 'Works as a freelancer',
          value: 'self-employed'
    value 'UNEMPLOYED', "Doesn't work for money",
          value: 'unemployed'
  end
end
