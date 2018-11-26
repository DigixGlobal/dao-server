# frozen_string_literal: true

require 'json'
require 'uri'
require 'net/http'
require 'net/https'

require 'info_server'

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  INFO_SERVER_URL = ENV.fetch('INFO_SERVER_URL') { 'http://localhost:3001' }
  INFO_SERVER_NAME = Rails.configuration.nonces['info_server_name']

  def render_invalid_info_request(error)
    render json: { message: error.message },
           status: :forbidden
  end

  rescue_from InfoServer::InvalidRequest,
              with: :render_invalid_info_request

  private

  def error_response(error = 'Error')
    render json: { error: error }
  end

  def request_info_server(endpoint, payload)
    new_nonce = increase_self_nonce

    # compute sig
    digest = OpenSSL::Digest.new('sha256')

    message = 'POST' + endpoint + payload.to_json + new_nonce.to_s
    signature = OpenSSL::HMAC.hexdigest(digest, SERVER_SECRET, message)

    # form uri
    uri = URI.parse("#{INFO_SERVER_URL}#{endpoint}")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = {
                                'Content-Type' => 'application/json',
                                'ACCESS-SIGN' => signature,
                                'ACCESS-NONCE' => new_nonce.to_s
                              })
    req.body = { payload: payload }.to_json
    res = https.request(req)
    res
  end

  def check_info_server_request
    unless request.headers.include?('ACCESS-NONCE') &&
           request.headers.include?('ACCESS-SIGN') &&
           request.parameters.key?('payload')
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
end
