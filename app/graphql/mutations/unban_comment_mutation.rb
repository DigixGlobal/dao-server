# frozen_string_literal: true

module Mutations
  class UnbanCommentMutation < Types::Base::BaseMutation
    description <<~EOS
      As a forum admin, unban a banned comment which reveals the comment contents to other users.

      Role: Forum Admin
    EOS

    argument :comment_id, String,
             required: true,
             description: <<~EOS
               Comment ID
             EOS

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Unbanned user'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Comment not found
            - Comment already unbanned
          EOS

    def resolve(comment_id:)
      forum_admin = context.fetch(:current_user)

      key = :comment

      unless (this_comment = Comment.find_by(id: comment_id))
        return form_error(key, 'comment_id', 'Comment not found')
      end

      result, comment_or_errors = Comment.unban(forum_admin, this_comment)

      case result
      when :comment_already_unbanned
        form_error(key, '_', 'Comment already unbanned')
      when :ok
        model_result(key, comment_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:unban, Comment)
    end
  end
end
