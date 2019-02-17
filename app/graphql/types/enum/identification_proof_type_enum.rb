# frozen_string_literal: true

module Types
  module Enum
    class IdentificationProofTypeEnum < Types::Base::BaseEnum
      description "Customer's ID proof type"

      value 'PASSPORT', 'International passport',
            value: 'passport'
      value 'NATIONAL_ID', 'National ID Card(Singapore Residents only)',
            value: 'national_id'
      value 'IDENTITY_CARD', 'National Identity Card (Drivers License not accepted)',
            value: 'identity_card'
    end
  end
end
