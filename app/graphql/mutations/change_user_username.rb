# frozen_string_literal: true

module Mutations
  class ChangeUserUsername < Types::BaseMutation
    description <<~EOS
      Set the current user's username.

      You can only change your username ONCE so make sure to commit to this.
    EOS

    argument :username, String,
             required: true,
             description: <<~EOS
               Username for the user.
                Requirements:
               - 2 to 20 characters long
               - Alphanumerical characters plus underscore
               - Must not start with "user"
             EOS

    field :user, Types::UserType,
          null: true,
          description: 'User with the updated email'
    field :errors, [UserErrorType],
          null: false,
          description: 'Mutation errors'

    def resolve(username:)
      user = context.fetch(:current_user)

      result, user_or_errors = User.change_username(user, username)

      key = :user

      case result
      when :username_already_set
        form_error(key, 'username', 'Username already set')
      when :invalid_data
        model_errors(user_or_errors, key)
      when :ok
        model_result(user_or_errors, key)
      end
    end

    def self.authorized?(object, context)
      super && context.fetch(:current_user, nil)
    end

    def self.visible?(context)
      authorized?(nil, context)
    end
  end
end
