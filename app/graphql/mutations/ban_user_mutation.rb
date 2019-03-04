# frozen_string_literal: true

module Mutations
  class BanUserMutation < Types::Base::BaseMutation
    description <<~EOS
      As a forum admin, ban a user from commenting in the forum.

      Role: Forum Admin
    EOS

    argument :id, String,
             required: true,
             description: <<~EOS
               ID of the user to ban
             EOS

    field :user, Types::User::DaoUserType,
          null: true,
          description: 'Banned user'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - User not found
            - User already banned
            - User cannot be banned
          EOS

    def resolve(id:)
      forum_admin = context.fetch(:current_user)

      key = :user

      unless (this_user = User.find_by(id: id))
        return form_error(key, 'id', 'User not found')
      end

      result, user_or_errors = User.ban_user(forum_admin, this_user)

      case result
      when :user_already_banned
        form_error(key, '_', 'User already banned')
      when :unauthorized_action
        form_error(key, '_', 'User cannot be banned')
      when :ok
        model_result(key, user_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:ban, User)
    end
  end
end
