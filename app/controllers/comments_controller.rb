# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!,
                only: %i[like unlike]

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
end
