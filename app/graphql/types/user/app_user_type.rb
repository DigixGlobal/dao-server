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
      field :is_under_maintenance, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating if the application is undergoing maintenance
               and should not be used by the user for the meantime.
            EOS
    end
  end
end
