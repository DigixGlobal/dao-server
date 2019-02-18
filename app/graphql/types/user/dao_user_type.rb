# frozen_string_literal: true

require 'cancancan'

module Types
  module User
    class DaoUserType < Types::User::AuthorizedUserType
      description 'Users managed by the forum admin'

      field :is_banned, Boolean,
            null: false,
            description: <<~EOS
              A flag indicating if the user is banned from the project forum
            EOS

      def self.authorized?(_object, context)
        super && context.fetch(:current_user, nil)
      end
    end
  end
end
