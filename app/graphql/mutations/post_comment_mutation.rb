# frozen_string_literal: true

module Mutations
  class PostCommentMutation < Types::Base::BaseMutation
    description 'Post a new comment or reply to one'

    argument :proposal_id, String,
             required: false,
             description: 'Eth contract address of the proposal'
    argument :comment_id, String,
             required: false,
             description: 'Comment ID'
    argument :body, String,
             required: true,
             description: <<~EOS
               Message body of the comment.

               Currently, accepts any text so passing in HTML is discouraged.
             EOS

    field :comment, Types::Proposal::CommentType,
          null: true,
          description: 'Newly published comment'
    field :errors, [UserErrorType],
          null: false,
          description: <<~EOS
            Mutation errors

            Operation Errors:
            - Proposal not found
            - Comment not found
            - Comment cannot be posted
          EOS

    def resolve(comment_id: nil, proposal_id: nil, body: '')
      key = :comment

      this_comment = if proposal_id
                       unless (proposal = Proposal.find_by(proposal_id: proposal_id))
                         return form_error(key, 'proposal_id', 'Proposal not found')
                       end

                       proposal.comment
                     elsif comment_id
                       unless (comment = Comment.find_by(id: comment_id))
                         return form_error(key, 'comment_id', 'Comment not found')
                       end

                       comment
                     else
                       return form_error(key, '_', 'Must have a proposal id or comment id')

                       nil
                end

      result, comment_or_errors = Comment.comment(
        context.fetch(:current_user),
        this_comment,
        body: sanitize(body)
      )

      case result
      when :invalid_data
        model_errors(key, comment_or_errors)
      when :database_error, :unauthorized_action
        form_error(key, '_', 'Comment cannot be posted')
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

    def sanitize(text)
      Sanitize.fragment(
        text,
        elements: %w[p strong em u h1 h2 h3 a ol ul li],
        attributes: {
          'a' => %w[href title target],
          'li' => ['class']
        },
        protocols: {
          'a' => { 'href' => %w[http https mailto] }
        }
      )
    end

    def self.authorized?(object, context)
      super &&
        (user = context.fetch(:current_user, nil)) &&
        Ability.new(user).can?(:create, Comment)
    end
  end
end
