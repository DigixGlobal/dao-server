# frozen_string_literal: true

module Types
  module Enum
    class GenderEnum < Types::Base::BaseEnum
      description "Customer's gender be it male or female"

      value 'MALE', 'To be endorsed by a moderator',
            value: 'male'
      value 'FEMALE', 'To be voted on',
            value: 'female'
    end
  end
end
