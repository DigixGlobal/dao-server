# frozen_string_literal: true

module Types
  module Enum
    class KycStatusEnum < Types::Base::BaseEnum
      description 'Kyc stages or phases'

      value 'PENDING', 'Kyc still pending or waiting to be approved',
            value: 'pending'
      value 'REJECTED', 'Kyc was rejected',
            value: 'rejected'
      value 'EXPIRED', 'Kyc expired and user must resubmit',
            value: 'expired'
      value 'APPROVED', 'Kyc is approved',
            value: 'approved'
    end
  end
end
