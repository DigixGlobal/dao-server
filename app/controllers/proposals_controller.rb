# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[create]
  before_action :authenticate_user!,
                only: %i[find show]
  before_action :throttle_commenting!,
                only: %i[comment reply]

  def_param_group :proposal do
    property :proposal_id, /0x\w+{64}/, desc: 'Proposal id, no '
    property :user_id, Integer, desc: "Proposer's user id"
    property :stage, Proposal.stages.keys, desc: 'Current stage/phase of the proposal'
    property :likes, Integer, desc: 'Number of likes'
    property :liked, [true, false],
             desc: <<~EOS
               True if the current use liked this proposal.

               Not present if request comes from the info server.
             EOS
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
    property :comment_id, Integer,
             desc: <<~EOS
               Root comment id for the proposal.

               When making a top level comment, use this id.
             EOS
  end

  api :POST, 'proposals', 'Create a proposal. Used by info-server.'
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :proposal_id, /0x\w+{64}/, desc: 'The id address of the proposal.',
                                     required: true
    param :proposer, /0x\w+{40}/, desc: "The proposer's address",
                                  required: true
  end
  tags [:info_server]
  formats [:json]
  returns :proposal, desc: 'Created proposal'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        desc: 'Database error. Commonly the proposal id already exists.',
        meta: { error: :database_error }
  example <<~EOS
    {
      "result": {
        "proposalId": "0xcef1400cde60a2e17dfdc68c35466d204a5dcf83",
        "userId": 82,
        "stage": "idea",
        "likes": 0,
        "createdAt": "2018-12-14T11:06:10.000+08:00",
        "updatedAt": "2018-12-14T11:06:10.000+08:00",
        "commentId": 79
      }
    }
  EOS
  def create
    result, proposal_or_error = Proposal.create_proposal(create_params)

    case result
    when :invalid_data, :database_error
      render json: error_response(proposal_or_error)
    when :ok
      render json: result_response(proposal_or_error)
    end
  end

  api :GET, 'proposals/:proposal_id', 'Get a proposal given its proposal id'
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :proposal_id, /0x\w+{64}/, desc: 'The id address of the proposal.',
                                     required: true
    param :proposer, /0x\w+{40}/, desc: "The proposer's address",
                                  required: true
  end
  tags [:info_server]
  formats [:json]
  returns :proposal, desc: 'Created proposal'
  error code: :ok, desc: 'Validation errors',
        meta: { error: { field: [:validation_error] } }
  error code: :ok,
        desc: 'Database error. Commonly the proposal id already exists.',
        meta: { error: :database_error }
  example <<~EOS
    {
      "result": {
        "proposalId": "0xcef1400cde60a2e17dfdc68c35466d204a5dcf83",
        "userId": 82,
        "stage": "idea",
        "likes": 0,
        "createdAt": "2018-12-14T11:06:10.000+08:00",
        "updatedAt": "2018-12-14T11:06:10.000+08:00",
        "commentId": 79
      }
    }
  EOS
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
