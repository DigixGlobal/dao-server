# frozen_string_literal: true

class InfoServer
  SERVER_SECRET = ENV.fetch(
    'DAO_INFO_SERVER_SECRET',
    'this-is-a-secret-between-dao-and-info-server'
  )
  INFO_SERVER_NAME = Rails.configuration.nonces['info_server_name']

  class << self
  def request_signature(request)
    message_signature(request_message(request))
  end

  def access_signature(method, path, nonce, payload)
    message_signature(access_message(method, path, nonce, payload))
  end

  def current_nonce
    Nonce.find_by(server: INFO_SERVER_NAME).nonce
  end

  def update_nonce(latest_nonce)
    nonce = Nonce.find_by(server: INFO_SERVER_NAME)

    nonce.update(nonce: latest_nonce) if nonce.nonce < latest_nonce
  end

    private

  def message_signature(message)
    digest = OpenSSL::Digest.new('sha256')

    OpenSSL::HMAC.hexdigest(digest, SERVER_SECRET, message)
  end

  def access_message(method, path, nonce, payload)
    "#{method}#{path}#{payload.to_json}#{nonce}"
  end

  def request_message(request)
    access_message(
      request.method,
      request.original_fullpath,
      request.headers.fetch('ACCESS-NONCE', '').to_i,
      request.params.fetch('payload', '')
    )
  end
  end

  class InvalidRequest < StandardError; end
end
