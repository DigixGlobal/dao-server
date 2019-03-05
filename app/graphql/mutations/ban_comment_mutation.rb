# frozen_string_literal: true

module Mutations
  class BanCommentMutation < Types::Base::BaseMutation
    description <<~EOS
      As a forum admin, ban a comment so that its contents are hidden from other users.

      Role: Forum Admin
    EOS

    argument :comment_id, String,
             required: true,
             description: <<~EOS
               Comment ID
             EOS

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Banned comment'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Comment not found
            - Comment already banned
            - Comment cannot be banned
          EOS

    def resolve(comment_id:)
      forum_admin = context.fetch(:current_user)

      key = :comment

      unless (this_comment = Comment.find_by(id: comment_id))
        return form_error(key, 'comment_id', 'Comment not found')
      end

      result, comment_or_errors = Comment.ban(forum_admin, this_comment)

      case result
      when :comment_already_banned
        form_error(key, '_', 'Comment already banned')
      when :unauthorized_action
        form_error(key, '_', 'Comment cannot be banned')
      when :ok
        model_result(key, comment_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:ban, Comment)
    end
  end
end
