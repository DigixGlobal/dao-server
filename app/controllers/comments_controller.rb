# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!,
                only: %i[like unlike comment delete]
  before_action :throttle_commenting!,
                only: %i[comment]

  class ActionThrottled < StandardError; end

  COMMENT_THROTTLE_PERIOD = Rails
                            .configuration
                            .proposals['comment_throttle_period']
                            .to_i

  rescue_from ActionThrottled,
              with: :render_action_throttled

  def render_action_throttled(_error)
    render json: error_response(:action_throttled),
           status: :forbidden
  end

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
    when :invalid_data, :database_error
      render json: error_response(comment_or_error)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

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

  def comment_params
    params.permit(:body)
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
