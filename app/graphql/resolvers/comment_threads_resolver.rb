# frozen_string_literal: true

module Resolvers
  class CommentThreadsResolver < Resolvers::Base
    type Types::CommentType.connection_type,
         null: false

    argument :proposal_id, String,
             required: false,
             description: <<~EOS
               Search proposal threads by proposal id address.
                This is required or the comment id.
               Also this takes precedence if both exists.
             EOS
    argument :comment_id, String,
             required: false,
             description: <<~EOS
               Search comment replies by its id.
                This is required or proposal id.
             EOS
    argument :stage, Types::StageType,
             required: false,
             description: <<~EOS
               Filter comments by stage/phase.
                If not specified, it defaults to the current stage.
             EOS
    argument :sort_by, Types::ThreadSortByType,
             required: false,
             default_value: 'latest',
             description: 'Sorting options for the threads'

    def comment_threads(**attrs)
      comment = if (proposal_id = attrs.fetch(:proposal_id, nil))
                  unless (proposal = Proposal.find_by(proposal_id: proposal_id))
                    raise GraphQL::ExecutionError, "Proposal #{proposal_id} does not exist"
                  end

                  proposal.comment
                elsif (comment_id = attrs.fetch(:comment_id, nil))
                  unless (comment = Comment.find_by(id: comment_id))
                    raise GraphQL::ExecutionError, "Comment #{comment_id} does not exist"
                  end

                  comment
                else
                  raise GraphQL::ExecutionError, 'Must provide a proposal id or comment id'
                end

      Comment.select_batch_user_comment_replies(
        [comment.id],
        context[:current_user],
        attrs
      )
    end
  end
end
