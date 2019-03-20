# frozen_string_literal: true

module Mutations
  class UnpostCommentMutation < Types::Base::BaseMutation
    description <<~EOS
      Unpost/remove/delete a comment.

      Can only unpost a comment you posted.
    EOS

    argument :comment_id, String,
             required: true,
             description: 'Comment ID'

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Unposted comment'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Comment not found
            - Comment already unposted
            - Comment cannot be unposted
          EOS

    def resolve(comment_id:)
      key = :comment

      unless (this_comment = Comment.find_by(id: comment_id))
        return form_error(key, 'comment_id', 'Comment not found')
      end

      result, comment_or_errors = Comment.delete(
        context[:current_user],
        this_comment
      )

      case result
      when :already_deleted
        form_error(key, '_', 'Comment already unposted')
      when :unauthorized_action
        form_error(key, '_', 'Comment cannot be unposted')
      when :ok
        DaoServerSchema.subscriptions.trigger(
          'commentUpdated',
          {},
          { comment: comment_or_errors },
          {}
        )

        model_result(key, comment_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:delete, Comment)
    end
  end
end
