# frozen_string_literal: true

require 'info_api'

module Types
  class ThreadSortByType < Types::BaseEnum
    value 'LATEST', 'Sort in descending creation time',
          value: 'latest'
    value 'OLDEST', 'Sort in ascending creation time',
          value: 'oldest'
  end

  class QueryType < Types::BaseObject
    field :viewer, AuthorizedUserType,
          null: false,
          description: "Get the current user's information"
    def viewer
      context[:current_user]
    end

    field :search_proposals, [ProposalType],
          null: false,
          description: 'Search for proposals/projects' do
      argument :proposal_ids, [String],
               required: false,
               description: 'Filter proposals by a list of proposal id addresses'
      argument :stage, StageType,
               required: false,
               description: 'Filter proposals by its stage/phase'
      argument :liked, Boolean,
               required: false,
               description: 'Filter proposals if it is liked or not by the current user'
      argument :sort_by, SortByType,
               required: false,
               default_value: 'desc',
               description: 'Sorting options for the proposals'
    end

    field :search_comment_threads, CommentType.connection_type,
          null: false,
          description: 'Proposals' do
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
      argument :stage, StageType,
               required: false,
               description: <<~EOS
                 Filter comments by stage/phase.

                 If not specified, it defaults to the current stage.
               EOS
      argument :sort_by, ThreadSortByType,
               required: false,
               default_value: 'latest',
               description: 'Sorting options for the threads'
    end

    def search_proposals(**attrs)
      dao_proposals = Proposal.select_user_proposals(
        context[:current_user],
        attrs
      )

      result, info_proposals_or_error = InfoApi.list_proposals

      raise GraphQL::ExecutionError, 'Network failure' unless result == :ok

      merge_by_keys(dao_proposals, info_proposals_or_error, :proposal_id)
    end

    def search_comment_threads(**attrs)
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

    private

    def merge_by_keys(left, right, key)
      return [] if left.nil? || left.empty?
      return left if right.nil? || right.empty?

      right_hash = Hash[right.map { |item| [item[key], item.to_h] }]
      left.map { |item| item.class.new(item.attributes.merge(right_hash.fetch(item[key], {}))) }
    end
  end
end
