# frozen_string_literal: true

module Types
  class ResidenceProofTypeEnum < Types::BaseEnum
    description 'Type of customer residence proof'

    value 'UTILITY_BILL', 'Utility bill such as electricity or water',
          value: 'utility_bill'
    value 'BANK_STATEMENT', 'Bank statement',
          value: 'bank_statement'
  end
end
