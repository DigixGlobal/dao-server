# frozen_string_literal: true

module Mutations
  class UnlikeCommentMutation < Types::Base::BaseMutation
    description 'Given a user liked comment, unlike the comment'

    argument :comment_id, String,
             required: true,
             description: 'Comment ID'

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Unliked comment'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Comment not found
            - Comment already unliked
          EOS

    def resolve(comment_id:)
      key = :comment

      unless (this_comment = Comment.find_by(id: comment_id))
        return form_error(key, 'comment_id', 'Comment not found')
      end

      result, comment_or_errors = Comment.unlike(
        context[:current_user],
        this_comment
      )

      case result
      when :not_liked
        form_error(key, '_', 'Comment not liked')
      when :ok
        model_result(key, comment_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:unlike, Comment)
    end
  end
end
