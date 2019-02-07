# frozen_string_literal: true

module Mutations
  class ChangeUsernameMutation < Types::BaseMutation
    description <<~EOS
      Set the current user's username.

      Username can only be changed ONCE so caution with this operation.
    EOS

    argument :username, String,
             required: true,
             description: <<~EOS
               Username for the user.

               Validations:
               - Minimum of 2 characters
               - Maximum of 150 characters
               - Alphanumerical characters plus underscore
               - Must not start with `user`
             EOS

    field :user, Types::AuthorizedUserType,
          null: true,
          description: 'User with the updated email'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Username is already set
          EOS

    def resolve(username:)
      user = context.fetch(:current_user)
      this_user = User.find(user.id)

      result, user_or_errors = User.change_username(this_user, username)

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
  end
end
