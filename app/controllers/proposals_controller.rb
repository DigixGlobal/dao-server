# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request, only: %i[create]
  before_action :authenticate_user!, only: %i[find comment delete_comment]

  def create
    base_params = create_params
    attrs = {
      id: base_params.fetch('proposal_id', nil),
      proposer: base_params.fetch('proposer', nil)
    }

    result, proposal_or_error = Proposal.create_proposal(attrs)

    case result
    when :invalid_data, :database_error
      render json: error_response(proposal_or_error)
    when :ok
      render json: result_response(proposal_or_error)
    end
  end

  def find
    case (proposal = Proposal.find_by(id: params.fetch(:id)))
    when nil
      render json: error_response(:proposal_not_found),
             status: :not_found
    else
      render json: result_response(proposal)
    end
  end

  def comment
    unless (proposal = Proposal.find_by(id: params.fetch(:id)))
      return render json: error_response(:proposal_not_found),
                    status: :not_found
    end

    parent_comment = nil

    if params.key?(:comment_id)
      unless (parent_comment = Comment.find_by(id: params.fetch(:comment_id)))
        return render json: error_response(:comment_not_found),
                      status: :not_found
      end
    end

    user = current_user

    result, comment_or_error = Proposal.comment(
      proposal,
      user,
      parent_comment,
      comment_params
    )

    case result
    when :unauthorized_action
      render json: error_response(result),
             status: :forbidden
    when :invalid_data, :database_error, :already_deleted
      render json: error_response(comment_or_error)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  def delete_comment
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

  def create_params
    return {} if params.fetch(:payload, nil).nil?

    params.require(:payload).permit(:proposal_id, :proposer)
  end

  def comment_params
    params.permit(:body)
  end
end
