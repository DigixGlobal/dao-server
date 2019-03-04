# frozen_string_literal: true

require 'base64'

module Resolvers
  class CommentThreadsResolver < Resolvers::Base
    type Types::Proposal::CommentThreadConnectionType,
         null: false

    argument :first, Int,
             required: false,
             default_value: 10,
             description: 'Returns the first _n_ elements from the list.'
    argument :after, String,
             required: false,
             description: 'Returns the elements in the list that come after the specified cursor.'

    argument :proposal_id, String,
             required: false,
             description: <<~EOS
               Search comment threads by proposal id address.
                This is required or comment id.

               Also this takes precedence if both exists.
             EOS
    argument :comment_id, String,
             required: false,
             description: <<~EOS
               Search comment replies by its id.
                This is required or proposal id.
             EOS
    argument :stage, Types::Enum::ProposalStageEnum,
             required: false,
             description: <<~EOS
               Filter comments by stage/phase.
                If not specified, it defaults to the current stage.
             EOS
    argument :sort_by, Types::Enum::ThreadSortByEnum,
             required: false,
             default_value: 'latest',
             description: 'Sorting options for the threads'

    def resolve(first:, after: nil, proposal_id: nil, comment_id: nil, **attrs)
      comment = if proposal_id
                  unless (proposal = Proposal.find_by(proposal_id: proposal_id))
                    raise GraphQL::ExecutionError, "Proposal #{proposal_id} does not exist"
                  end

                  proposal.comment
                elsif comment_id
                  unless (comment = Comment.find_by(id: comment_id))
                    raise GraphQL::ExecutionError, "Comment #{comment_id} does not exist"
                  end

                  comment
                else
                  raise GraphQL::ExecutionError, 'Must provide a proposal id or comment id'
                end

      if after
        begin
          json = Base64.strict_decode64(after)
          data = JSON.parse(json)

          if (raw_date_after = data.fetch('date_after', nil))
            attrs[:date_after] = DateTime.parse(raw_date_after)
          end

          unless (parent_comment = Comment.find_by(id: data.fetch('parent_id', nil)))
            raise GraphQL::CoercionError, "#{after} is not a valid cursor"
          end

          unless parent_comment.id == comment.id || parent_comment.descendant_of?(comment)
            raise GraphQL::CoercionError, "#{after} is not a valid cursor"
          end

          comment = parent_comment
        rescue ArgumentError, JSON::ParserError
          raise GraphQL::CoercionError, "#{after} is not a valid cursor"
        end
      end

      comments = Comment.select_batch_user_comment_replies(
        [comment.id],
        context[:current_user],
        first + 1,
        attrs
      )

      items = comments.slice(0, first)
      has_next_page = comments.size > first

      connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes([comment])
      connection_class.new(
        items,
        has_next_page: has_next_page,
        end_cursor: has_next_page ? { parent_id: comment.id, date_after: items.last&.created_at&.iso8601 } : nil
      )
    end
  end
end
