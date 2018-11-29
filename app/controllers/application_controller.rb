# frozen_string_literal: true

require 'json'
require 'uri'
require 'net/http'
require 'net/https'

require 'info_server'
require 'self_server'

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  def render_invalid_info_request(error)
    render json: { message: error.message },
           status: :forbidden
  end

  rescue_from InfoServer::InvalidRequest,
              with: :render_invalid_info_request

  private

  def result_response(result = :ok)
    { result: result }
  end

  def error_response(error = 'Error')
    { error: error }
  end

  def check_info_server_request
    unless request.headers.include?('ACCESS-NONCE') &&
           request.headers.include?('ACCESS-SIGN') &&
           request.params.key?('payload')
      raise  InfoServer::InvalidRequest,
             'Info server requests must have a "payload" parameter and "ACCESS-NONCE" and "ACCESS-SIGN" header.'
    end

    request_nonce = request.headers.fetch('ACCESS-NONCE', '').to_i
    request_signature = request.headers.fetch('ACCESS-SIGN', '')

    valid_signature = InfoServer.request_signature(request)
    valid_nonce = InfoServer.current_nonce

    unless request_signature == valid_signature
      raise InfoServer::InvalidRequest,
            'Invalid signature provided.'
    end

    unless request_nonce > valid_nonce
      raise  InfoServer::InvalidRequest,
             'Invalid nonce provided.'
    end
  end

  def update_info_server_nonce
    if request.headers.include?('ACCESS-NONCE')
      request_nonce = request.headers.fetch('ACCESS-NONCE', '').to_i

      InfoServer.update_nonce(request_nonce)
    end
  end

  def check_and_update_info_server_request
    check_info_server_request
    yield
    update_info_server_nonce
  end
end
