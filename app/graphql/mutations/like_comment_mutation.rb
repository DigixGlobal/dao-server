# frozen_string_literal: true

module Mutations
  class LikeCommentMutation < Types::Base::BaseMutation
    description 'Given a unliked comment, like the comment'

    argument :comment_id, String,
             required: true,
             description: 'Comment ID'

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Liked comment'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Comment not found
            - Comment already liked
            - Comment cannot be liked
          EOS

    def resolve(comment_id:)
      key = :comment

      unless (this_comment = Comment.find_by(id: comment_id))
        return form_error(key, 'comment_id', 'Comment not found')
      end

      result, comment_or_errors = Comment.like(
        context[:current_user],
        this_comment
      )

      case result
      when :already_liked
        form_error(key, '_', 'Comment already liked')
      when :ok
        model_result(key, comment_or_errors)
      end
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:like, Comment)
    end
  end
end
