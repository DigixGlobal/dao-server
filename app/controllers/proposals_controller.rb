# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request, only: %i[create]
  before_action :authenticate_user!, only: %i[find comment]

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

  # TODO: Last
  def find
  end

  def comment
    proposal = Proposal.find_by(id: params.fetch(:id))

    render json: error_response(:proposal_not_found) unless proposal

    user = current_user

    attrs = { body: comment_params.fetch('comment', nil) }
    result, comment_or_error = Proposal.comment(proposal, user, attrs)

    case result
    when :invalid_data, :database_error
      render json: error_response(comment_or_error)
    when :ok
      render json: result_response(comment_or_error)
    end
  end

  def create_params
    params.require('payload').permit(:proposal_id, :proposer)
  end

  def comment_params
    params.permit(:comment)
  end
end
