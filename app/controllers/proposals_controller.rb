# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[create]
  before_action :authenticate_user!,
                only: %i[find show]
  before_action :throttle_commenting!,
                only: %i[comment reply]

  def create
    result, proposal_or_error = Proposal.create_proposal(create_params)

    case result
    when :invalid_data, :database_error
      render json: error_response(proposal_or_error)
    when :ok
      render json: result_response(proposal_or_error)
    end
  end

  def show
    proposal_id = params.fetch(:proposal_id)
    case (proposal = Proposal.find_by(proposal_id: proposal_id))
    when nil
      render json: error_response(:proposal_not_found),
             status: :not_found
    else
      render json: result_response(user_proposal_view(current_user, proposal))
    end
  end

  def like
    proposal_id = params.fetch(:proposal_id)
    unless (proposal = Proposal.find_by(proposal_id: proposal_id))
      return render json: error_response(:proposal_not_found),
                    status: :not_found
    end

    result, proposal_or_error = Proposal.like(current_user, proposal)

    case result
    when :database_error, :already_liked
      render json: error_response(proposal_or_error || result)
    when :ok
      render json: result_response(
        user_proposal_view(current_user, proposal_or_error)
      )
    end
  end

  def unlike
    proposal_id = params.fetch(:proposal_id)
    unless (proposal = Proposal.find_by(proposal_id: proposal_id))
      return render json: error_response(:proposal_not_found),
                    status: :not_found
    end

    result, proposal_or_error = Proposal.unlike(current_user, proposal)

    case result
    when :database_error, :not_liked
      render json: error_response(proposal_or_error || result)
    when :ok
      render json: result_response(
        user_proposal_view(current_user, proposal_or_error)
      )
    end
  end

  private

  def create_params
    return {} if params.fetch(:payload, nil).nil?

    params.require(:payload).permit(:proposal_id, :proposer)
  end

  def user_proposal_view(user, proposal)
    proposal
      .as_json
      .merge(liked: proposal.user_liked?(user))
  end
end
