# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[create]
  before_action :authenticate_user!,
                only: %i[find]
  before_action :throttle_commenting!,
                only: %i[comment reply]

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

  def show
    case (proposal = Proposal.find_by(id: params.fetch(:id)))
    when nil
      render json: error_response(:proposal_not_found),
             status: :not_found
    else
      render json: result_response(user_proposal_view(current_user, proposal))
    end
  end

  def like
    unless (proposal = Proposal.find_by(id: params.fetch(:id)))
      return render json: error_response(:proposal_not_found),
                    status: :not_found
    end

    result, proposal_or_error = Proposal.like(current_user, proposal)

    case result
    when :database_error, :already_liked
      render json: error_response(proposal_or_error || result)
    when :ok
      render json: result_response(proposal_or_error)
    end
  end

  def unlike
    unless (proposal = Proposal.find_by(id: params.fetch(:id)))
      return render json: error_response(:proposal_not_found),
                    status: :not_found
    end

    result, proposal_or_error = Proposal.unlike(current_user, proposal)

    case result
    when :database_error, :not_liked
      render json: error_response(proposal_or_error || result)
    when :ok
      render json: result_response(proposal_or_error)
    end
  end

  private

  def create_params
    return {} if params.fetch(:payload, nil).nil?

    params.require(:payload).permit(:proposal_id, :proposer)
  end

  def user_proposal_view(user, proposal)
    proposal
      .serializable_hash
      .merge(threads: proposal.user_threads(user), liked: proposal.user_liked?(user))
  end
end
