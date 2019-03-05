# frozen_string_literal: true

module Types
  module Proposal
    class LazyCommentThread
      def initialize(query_ctx, object, batch_size)
        @comment = object
        @current_user = query_ctx[:current_user]
        @batch_size = batch_size

        @lazy_state = query_ctx[:lazy_comment_thread] ||= {
          pending_ids: Set.new,
          loaded_ids: {}
        }

        @lazy_state[:pending_ids] << @comment.id
      end

      def replies
        loaded_record = @lazy_state[:loaded_ids][@comment.id]

        if loaded_record
          @lazy_state[:pending_ids].delete(@comment.id)

          loaded_record
        else
          comment_ids = @lazy_state[:pending_ids].to_a

          replies = Comment.select_batch_user_comment_replies(
            comment_ids,
            @current_user,
            @batch_size + 1,
            sort_by: :oldest
          ).to_a

          connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes([@object])

          (comment_ids - replies.map(&:parent_id)).each do |parent_id|
            @lazy_state[:loaded_ids][parent_id] = connection_class.new(
              [],
              has_next_page: false,
              end_cursor: nil
            )
          end

          replies.group_by(&:parent_id)
                 .each do |parent_id, group|
            items = group.slice(0, @batch_size)
            has_next_page = group.size > @batch_size

            @lazy_state[:loaded_ids][parent_id] = connection_class.new(
              items,
              has_next_page: has_next_page,
              end_cursor: has_next_page ? { parent_id: parent_id, date_after: items.last&.created_at&.iso8601 } : nil
            )
          end

          @lazy_state[:pending_ids].clear

          @lazy_state[:loaded_ids][@comment.id]
        end
      end
    end
  end
end
