# frozen_string_literal: true

class ProposalsController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[create]
  before_action :authenticate_user!,
                only: %i[find show]
  before_action :throttle_commenting!,
                only: %i[comment reply]

  def_param_group :proposal do
    property :proposal_id, String, desc: <<~EOS
      The proposal's id.

      No plain id field since it is created by the info server
    EOS
    property :user_id, Integer, desc: "Proposer's user id"
    property :stage, Proposal.stages.keys, desc: 'Current stage/phase of the proposal'
    property :likes, Integer, desc: 'Number of likes'
    property :liked, [true, false], desc: <<~EOS
      True if the current use liked this proposal.

      Not present if request comes from the info server.
    EOS
    property :created_at, String, desc: 'Creation UTC date time'
    property :updated_at, String, desc: 'Last modified UTC date time'
    property :comment_id, Integer, desc: <<~EOS
      Root comment id for the proposal.

      When making a top level comment, use this id.
    EOS
  end

  api :POST, 'proposals',
      <<~EOS
        Create a new proposal.

        Used by info-server.
      EOS
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
        meta: { error: :database_error },
        desc: "Database error. Only if the proposal's id already exists."
  meta authorization: :nonce
  example <<~EOS
    {
      "result": {
        "proposalId": "0x6ed7c6b98cb9af985b24be5de1ce81ba58a38c14e28c18b91f6b93895173ec09",
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

  api :GET, 'proposals/:proposal_id',
      "Get a proposal's details given its proposal id"
  param :proposal_id, /0x\w+{64}/, desc: 'The id address of the proposal.',
                                   required: true
  formats [:json]
  returns :proposal, desc: 'Proposal with said proposal id'
  error code: :ok,
        meta: { error: :proposal_not_found },
        desc: 'Proposal not found given the proposal id'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "proposalId": "0x6ed7c6b98cb9af985b24be5de1ce81ba58a38c14e28c18b91f6b93895173ec09",
        "userId": 1,
        "stage": "archived",
        "likes": 0,
        "createdAt": "2018-12-14T11:01:59.000+08:00",
        "updatedAt": "2018-12-14T11:01:59.000+08:00",
        "commentId": 1,
        "liked": false
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

  api :POST, 'proposals/:proposal_id/likes', 'As the current user, like the proposal'
  param :proposal_id, /0x\w+{64}/, desc: 'The id address of the proposal',
                                   required: true
  formats [:json]
  returns :proposal, desc: <<~EOS
    Liked proposal.

    The property liked should be true and likes increased by one.
  EOS
  error code: :ok,
        meta: { error: :proposal_not_found },
        desc: 'Proposal not found given the proposal id'
  error code: :ok,
        meta: { error: :already_liked },
        desc: 'Cannot like a liked proposal'
  error code: :ok,
        meta: { error: :database_error },
        desc: 'Database error. Should not happen.'
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "likes": 1,
        "userId": 1,
        "commentId": 1,
        "proposalId": "0x6ed7c6b98cb9af985b24be5de1ce81ba58a38c14e28c18b91f6b93895173ec09",
        "stage": "archived",
        "createdAt": "2018-12-14T11:01:59.000+08:00",
        "updatedAt": "2018-12-14T13:11:11.000+08:00",
        "liked": true
      }
    }
  EOS
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

  api :DELETE, 'proposals/:proposal_id/likes',
      'As the current user, unlike the liked proposal'
  param :proposal_id, /0x\w+{64}/, desc: 'The id address of the proposal',
                                   required: true
  formats [:json]
  returns :proposal, desc: <<~EOS
    Proposal with the user's liked removed.

    The property liked should be false and likes decreased by one.
  EOS
  error code: :ok,
        meta: { error: :proposal_not_found },
        desc: 'Proposal not found given the proposal id'
  error code: :ok,
        meta: { error: :not_liked },
        desc: 'Cannot unlike an unliked proposal'
  error code: :ok,
        desc: 'Database error. Should not happen.',
        meta: { error: :database_error }
  meta authorization: :access_token
  example <<~EOS
    {
      "result": {
        "likes": 0,
        "userId": 1,
        "commentId": 1,
        "proposalId": "0x6ed7c6b98cb9af985b24be5de1ce81ba58a38c14e28c18b91f6b93895173ec09",
        "stage": "archived",
        "createdAt": "2018-12-14T11:01:59.000+08:00",
        "updatedAt": "2018-12-14T13:11:11.000+08:00",
        "liked": false
      }
    }
  EOS
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
