# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!,
                only: %i[select_threads like unlike comment delete]
  before_action :throttle_commenting!,
                only: %i[comment]

  class ActionThrottled < StandardError; end

  COMMENT_THROTTLE_PERIOD = Rails
                            .configuration
                            .proposals['comment_throttle_period']
                            .to_i

  rescue_from ActionThrottled,
              with: :render_action_throttled

  def_param_group :comment do
    property :id, Integer, desc: 'Comment id'
    property :user_id, Integer, desc: 'Commenter user id'
    property :user, Hash, desc: 'Commenter itself' do
      property :address, String, desc: "Commenter's address"
    end
    property :body, String, desc: <<~EOS
      Plain string body of text.

      When a comment is deleted, this is null or empty.
    EOS
    property :replies, Hash, desc: 'Replies wrapped in a paginated wrapper' do
      property :has_more, [true, false],
               desc: <<~EOS
                 A flag to indicate if more siblings can be fetched
                 beyond the last item of `data`
               EOS
      property :data, Array, of: Comment, desc: 'List of replies of the comment'
    end
    property :stage, Comment.stages.keys, desc: 'Comment stage/phase'
    property :likes, Integer,
             desc: 'Number of likes'
    property :liked, [true, false],
             desc: 'True if the current use liked this comment'
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
  end

  def render_action_throttled(_error)
    render json: error_response(:action_throttled),
           status: :forbidden
  end

  api :POST, 'comments/:id/threads?stage=:stage&last_seen_id=:last_seen_id&sort_by=:sort_by',
      <<~EOS
        Given a parent/root comment, fetch comments/replies in batches.

        Uses `Load More` pagination so to accomodate that
        each batch is wrapped inside a object with `hasMore` and `data` property.
        The idea is to render the comments in `data`, show a load more button if `hasMore` is `true`
        and if so use the last comment id in `data` for the `last_seen_id` for the next batch.

        Data fetched are paginated by depth: #{Comment::DEPTH_LIMITS.join(',')}.
        In this case, there are #{Comment::DEPTH_LIMITS[0]} top level comments
        and for each of its children have #{Comment::DEPTH_LIMITS[1]} child comments
        and so on.

        Also, deleted comments are still fetched but their `body` property is `null`.
      EOS
  param :id, Integer, desc: 'The id of the parent/root comment',
                      required: true
  param :stage, Comment.stages.keys,
        desc: <<~EOS
          Filter comments by stage/phase.

          At the moment, a child comment and its replies have the same stage
          since you cannot comment on a previous stage/phase.
          So make sure you set this to `null` or the same stage as the comment
          if its not the root comment.
        EOS
  param :last_seen_id, Integer,
        desc: <<~EOS
          Specify where the next batch of records should start given the comment's child id.

          Primarily meant for `Load More` pagination strategy.
          The idea is to request for an initial batch and take the last comment/reply id from `data`
          and use that id here until `hasMore` is `true` or exhausted.
        EOS
  param :sort_by, Comment::SORTING_OPTIONS,
        desc: <<~EOS
          Specify how the root comments should be sorted. The following options are available:

          - latest ::
            Sort by descending `createdAt` order
          - oldest ::
            Sort by ascending `createdAt` order.
            Default sorting if the option is `null` or not valid

          Note, this option does not work with child comment
          since they are sorted in ascending `createdAt` order.
        EOS
  formats [:json]
  returns :comment, desc: 'Created comment/reply'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        desc: 'Database error. Should not happen.',
        meta: { error: :database_error }
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "hasMore": true,
        "data": [
          {
            "id": 4,
            "stage": "draft",
            "userId": 5,
            "likes": 0,
            "createdAt": "2018-12-14T11:02:00.000+08:00",
            "updatedAt": "2018-12-14T11:02:00.000+08:00",
            "user": {
              "address": "0x8cdf8d9af01541b26878032b864796957c08ae74"
            },
            "body": "comment-4",
            "replies": {
              "hasMore": false,
              "data": [
                {
                  "id": 11,
                  "stage": "draft",
                  "userId": 12,
                  "likes": 0,
                  "createdAt": "2018-12-14T11:02:03.000+08:00",
                  "updatedAt": "2018-12-14T11:02:03.000+08:00",
                  "user": {
                    "address": "0x281fadbf3e8ee1fa709ab511ac6350f99c005be1"
                  },
                  "body": "comment-11",
                  "replies": {
                    "hasMore": false,
                    "data": []
                  },
                  "liked": false
                }
              ]
            },
            "liked": false
          }
        ]
      }
    }
  EOS
  def select_threads
    attrs = select_thread_params
    unless (comment = Comment.find_by(id: attrs.fetch(:id, nil)))
      return render json: error_response(:comment_not_found),
                    status: :not_found
    end

    if (stage = attrs.fetch(:stage, comment.stage, nil))
      unless Comment.stages.key?(stage)
        return render json: error_response(:invalid_stage),
                      status: :not_found
      end
    end

    comment_trees = comment.user_stage_comments(current_user, stage, attrs)

    render json: result_response(
      user_comment_tree_view(
        current_user,
        comment_trees
      )
    )
  end

  api :POST, 'comments', <<~EOS
    Comment/reply to a comment.

    To comment on a proposal, use the root comment id(`proposal.comment_id`) of that proposal.
  EOS
  param :id, Integer, desc: 'The parent comment id of the comment to reply/comment',
                      required: true
  param :body, String, desc: 'Plain string body',
                       required: true
  formats [:json]
  returns :comment, desc: 'Created comment/reply'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Should not happen.'
  error code: :forbidden,
        meta: { error: { field: [:validation_error] } },
        desc: <<~EOS
          Action throttled. You can only comment around #{COMMENT_THROTTLE_PERIOD} seconds.
        EOS
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 84,
        "stage": "archived",
        "userId": 82,
        "likes": 0,
        "createdAt": "2018-12-14T13:56:36.000+08:00",
        "updatedAt": "2018-12-14T13:56:36.000+08:00",
        "user": {
          "address": "0x22e8422744054e07f15a4d634747e5bed53b043d"
        },
        "body": "Latest comment #587",
        "replies": {
          "hasMore": false,
          "data": []
        },
        "liked": false
      }
    }
  EOS
  def comment
    unless (comment = Comment.find_by(id: params.fetch(:id)))
      return render json: error_response(:comment_not_found),
                    status: :not_found
    end

    user = current_user

    result, comment_or_error = Comment.comment(
      user,
      comment,
      comment_params
    )

    case result
    when :invalid_data, :database_error, :action_invalid
      render json: error_response(comment_or_error || result)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  api :DELETE, 'comments', <<~EOF
    Soft delete a comment or reply.
  EOF
  param :id, Integer, desc: 'The id of the comment',
                      required: true
  param :body, String, desc: 'Plain string body',
                       required: true
  formats [:json]
  returns :comment, desc: 'Deleted comment or reply'
  error code: :ok,
        meta: { error: :unauthorized_action },
        desc: 'Cannot delete comments of other users'
  error code: :ok,
        meta: { error: :unauthorized_action },
        desc: 'Cannot delete deleted comments'
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Should not happen.'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 85,
        "userId": 82,
        "stage": "archived",
        "likes": 0,
        "createdAt": "2018-12-14T14:55:32.000+08:00",
        "updatedAt": "2018-12-14T15:14:00.000+08:00",
        "user": {
          "address": "0x22e8422744054e07f15a4d634747e5bed53b043d"
        },
        "body": null,
        "replies": {
          "hasMore": false,
          "data": []
        },
        "liked": false
      }
    }
  EOS
  def delete
    unless (comment = Comment.find_by(id: params.fetch(:id)))
      return render json: error_response(:comment_not_found),
                    status: :not_found
    end

    user = current_user

    result, comment_or_error = Comment.delete(
      user,
      comment
    )

    case result
    when :unauthorized_action
      render json: error_response(result),
             status: :forbidden
    when :already_deleted
      render json: error_response(result),
             status: :not_found
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  api :POST, 'comments/:id/likes', 'Like a comment'
  param :id, Integer, desc: 'The id of the comment',
                      required: true
  formats [:json]
  see 'proposals#like', 'Proposal like'
  returns :comment, desc: <<~EOS
    Liked comment.

    The property liked should be true and likes increased by one.
  EOS
  error code: :ok,
        meta: { error: :comment_not_found },
        desc: 'Comment not found given the id'
  error code: :ok,
        meta: { error: :already_liked },
        desc: 'Cannot like a liked comment'
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Should not happen.'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 86,
        "likes": 1,
        "stage": "archived",
        "userId": 82,
        "createdAt": "2018-12-14T15:17:54.000+08:00",
        "updatedAt": "2018-12-14T15:18:17.000+08:00",
        "user": {
          "address": "0x22e8422744054e07f15a4d634747e5bed53b043d"
        },
        "body": "NEW COMMENT",
        "replies": {
          "hasMore": false,
          "data": []
        },
        "liked": true
      }
    }
  EOS
  def like
    unless (comment = Comment.find_by(id: params.fetch(:id)))
      return render json: error_response(:comment_not_found),
                    status: :not_found
    end

    result, comment_or_error = Comment.like(current_user, comment)

    case result
    when :database_error, :already_liked
      render json: error_response(comment_or_error || result)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  api :DELETE, 'comments/:id/likes', 'Unlike a liked comment'
  param :id, Integer, desc: 'The id of the comment',
                      required: true
  formats [:json]
  returns :comment, desc: <<~EOS
    Comment with the user's liked removed.
    The property liked should be false and likes decreased by one.
  EOS
  error code: :ok,
        meta: { error: :comment_not_found },
        desc: 'Comment not found given the comment id'
  error code: :ok,
        meta: { error: :not_liked },
        desc: 'Cannot unlike an unliked comment'
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Should not happen.'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "id": 86,
        "likes": 0,
        "stage": "archived",
        "userId": 82,
        "createdAt": "2018-12-14T15:17:54.000+08:00",
        "updatedAt": "2018-12-14T15:20:15.000+08:00",
        "user": {
          "address": "0x22e8422744054e07f15a4d634747e5bed53b043d"
        },
        "body": "NEW COMMENT",
        "replies": {
          "hasMore": false,
          "data": []
        },
        "liked": false
      }
    }
  EOS
  def unlike
    unless (comment = Comment.find_by(id: params.fetch(:id)))
      return render json: error_response(:comment_not_found),
                    status: :not_found
    end

    result, comment_or_error = Comment.unlike(current_user, comment)

    case result
    when :database_error, :not_liked
      render json: error_response(comment_or_error || result)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  private

  def user_comment_tree_view(user, comment_trees)
    comment_trees
  end

  def comment_params
    params.permit(:body)
  end

  def select_thread_params
    params.permit(:id, :stage, :last_seen_id, :sort_by)
  end

  def throttle_commenting!
    if (latest_comment = Comment
                           .where(['user_id = ?', current_user.id])
                           .order(created_at: :desc)
                           .first)
      throttled_period = Time.now - latest_comment.created_at
      raise ActionThrottled if throttled_period <= COMMENT_THROTTLE_PERIOD
    end
  end
end
