# frozen_string_literal: true

require 'self_server'

class InfoServer
  SERVER_URL = ENV.fetch('INFO_SERVER_URL') { 'http://localhost:3001' }
  SERVER_SECRET = ENV.fetch(
    'DAO_INFO_SERVER_SECRET',
    'this-is-a-secret-between-dao-and-info-server'
  )
  SERVER_NAME = Rails.configuration.nonces['info_server_name']

  class << self
  def request_signature(request)
    message_signature(request_message(request))
  end

  def access_signature(method, path, nonce, payload)
    message_signature(access_message(method, path, nonce, payload))
  end

  def current_nonce
    Nonce.find_by(server: SERVER_NAME).nonce
  end

  def update_nonce(latest_nonce)
    nonce = Nonce.find_by(server: SERVER_NAME)

    nonce.update(nonce: latest_nonce) if nonce.nonce < latest_nonce

    nonce.nonce
  end

  def update_hashes(txhashes)
    res = request_info_server('/transactions/watch', txns: txhashes)
    result = JSON.parse(res.body).dig('result')

    seen_txns, confirmed_txns = result.fetch_values('seen', 'confirmed')

    unless confirmed_txns.empty?
      confirmed_txns.each do |txn|
        Transaction
          .where(txhash: txn['txhash'])
          .update(status: 'confirmed', blockNumber: txn['blockNumber'])
      end
    end

    unless seen_txns.empty?
      seen_txns.each do |txn|
        Transaction
          .where(txhash: txn['txhash'])
          .update(status: 'seen', blockNumber: txn['blockNumber'])
      end
    end
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

  def request_info_server(endpoint, payload)
    new_nonce = SelfServer.increment_nonce

    signature = InfoServer.access_signature('POST', endpoint, new_nonce, payload)

    uri = URI.parse("#{SERVER_URL}#{endpoint}")
    https = Net::HTTP.new(uri.host, uri.port)
    # https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path,
                              'Content-Type' => 'application/json',
                              'ACCESS-SIGN' => signature,
                              'ACCESS-NONCE' => new_nonce.to_s)
    req.body = { payload: payload }.to_json

    https.request(req)
  end
  end

  class InvalidRequest < StandardError; end
end
