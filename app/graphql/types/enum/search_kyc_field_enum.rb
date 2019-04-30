# frozen_string_literal: true

module Types
  module Enum
    class SearchKycFieldEnum < Types::Base::BaseEnum
      description 'Fields to be sorted on for `searchKycs` query`'

      value 'USER_ID', "Client's user ID",
            value: 'user_id'
      value 'NAME', "Client's full name",
            value: 'name'
      value 'STATUS', 'KYC status',
            value: 'status'
      value 'COUNTRY_OF_RESIDENCE', "Client's country of residence",
            value: 'country'
      value 'NATIONALITY', "Client's country of residence",
            value: 'nationality'
      value 'LAST_UPDATED', 'KYC update timestamp',
            value: 'updated_at'
    end
  end
end
