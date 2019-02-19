# frozen_string_literal: true

require 'event_handler'

class EventController < ApplicationController
  around_action :check_and_update_info_server_request,
                only: %i[handle_event]

  api :POST, 'dao_event', <<~EOS
    Handle events from the info server.

    Primarily used to send email notifications when domain events are triggered.
  EOS
  param :payload, Hash, desc: 'Info Server payload wrapper' do
    param :event_type, String,
          desc: <<~EOS
            The event type to handle.

            Values
            - 1 [PROJECT_CREATED]
            - 2 [PROJECT_ENDORSED]
          EOS
    param :proposal_id, String,
          desc: 'Proposal ID'
    param :proposer, String,
          desc: 'Proposer Eth address'
  end
  meta authorization: :nonce
  formats [:json]
  returns desc: 'A blank response' do
    property :result, String, desc: 'Blank response'
  end
  def handle_event
    payload = handle_event_params

    result, = EventHandler.handle_event(payload)

    case result
    when :proposal_not_found
      render json: error_response(result),
             status: :not_found
    when :invalid_event_type
      render json: error_response(result)
    when :ok
      render json: result_response
    end
  end

  private

  def handle_event_params
    return {} if params.fetch(:payload, nil).empty?

    params.require(:payload).permit(%i[event_type proposer proposal_id])
  end
end
