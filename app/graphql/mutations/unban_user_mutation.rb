# frozen_string_literal: true

module Mutations
  class UnbanUserMutation < Types::Base::BaseMutation
    description <<~EOS
      As a forum admin, unban a banned user which allows them to comment again in the forum.

      Role: Forum Admin
    EOS

    argument :uid, String,
             required: true,
             description: <<~EOS
               UID of the user to ban
             EOS

    field :user, Types::User::DaoUserType,
          null: true,
          description: 'Unbanned user'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - User not found
            - User already unbanned
          EOS

    def resolve(uid:)
      forum_admin = context.fetch(:current_user)

      key = :user

      unless (this_user = User.find_by(uid: uid))
        return form_error(key, 'uid', 'User not found')
      end

      result, user_or_errors = User.unban_user(forum_admin, this_user)

      case result
      when :user_already_unbanned
        form_error(key, '_', 'User already unbanned')
      when :ok
        model_result(key, user_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:unban, User)
    end
  end
end
