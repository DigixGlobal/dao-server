# frozen_string_literal: true

require 'cancancan'

module Types
  module User
    class AppUserType < Types::Base::BaseObject
      description 'Application user status such as access.'

      field :is_unavailable, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating if the application cannot be used by the user.
            EOS
    end
  end
end
