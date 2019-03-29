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
    render json: error_response(error.message),
           status: :forbidden
  end

  rescue_from InfoServer::InvalidRequest,
              with: :render_invalid_info_request

  private

  def sanitize_params(this_params)
    this_params
      .transform_values do |value|
        case value
        when String
          Sanitize.fragment(value)
        else
          value
        end
      end
  end

  def result_response(result = :ok)
    { result: result }
  end

  def error_response(error = :error)
    { error: error }
  end

  def check_info_server_request
    unless (request_nonce = request.headers.fetch('ACCESS-NONCE', '').to_i)
      raise InfoServer::InvalidRequest, :missing_access_nonce
    end

    unless (request_signature = request.headers.fetch('ACCESS-SIGN', ''))
      raise InfoServer::InvalidRequest, :missing_access_signature
    end

    unless request.params.key?('payload')
      raise InfoServer::InvalidRequest, :missing_payload
    end

    valid_signature = InfoServer.request_signature(request)

    unless request_signature == valid_signature
      raise InfoServer::InvalidRequest, :invalid_signature
    end

    valid_nonce = InfoServer.current_nonce

    unless request_nonce > valid_nonce
      raise InfoServer::InvalidRequest, :invalid_nonce
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
