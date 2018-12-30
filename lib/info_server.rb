# frozen_string_literal: true

require 'self_server'

# Module to manage info server communication and utilities
class InfoServer
  SERVER_URL = ENV.fetch('INFO_SERVER_URL') { 'http://localhost:3001' }
  SERVER_SECRET = ENV.fetch(
    'DAO_INFO_SERVER_SECRET',
    'this-is-a-secret-between-dao-and-info-server'
  )
  SERVER_NAME = Rails.configuration.nonces['info_server_name']

  class << self
  # Given an HTTP request, compute the access signature required for
  # authentication
  def request_signature(request)
    message_signature(request_message(request))
  end

  # The more explicit form of `request_signature` but takes the request
  # method("GET"/"POST"), the path of the
  # request("/url/path?with=parameters"), the request nonce and the
  # payload
  def access_signature(method, path, nonce, payload)
    message_signature(access_message(method, path, nonce, payload))
  end

  # Get the current seen nonce by the info server
  def current_nonce
    Nonce.find_by(server: SERVER_NAME).nonce
  end

  # Update the seen nonce of the info server
  def update_nonce(latest_nonce)
    nonce = Nonce.find_by(server: SERVER_NAME)

    nonce.update(nonce: latest_nonce) if nonce.nonce < latest_nonce

    latest_nonce
  end

  # Fetch transactions from the info server and sync with the local data
  def update_hashes(txhashes)
    result, payload_or_error = request_info_server('/transactions/watch', txns: txhashes)

    return [result, payload_or_error] unless result == :ok

    seen_txns, confirmed_txns = payload_or_error.fetch_values('seen', 'confirmed')

    unless confirmed_txns.empty?
      confirmed_txns.each do |txn|
        Transaction
          .where(txhash: txn['txhash'])
          .update(status: 'confirmed', block_number: txn['blockNumber'])
      end
    end

    unless seen_txns.empty?
      seen_txns.each do |txn|
        Transaction
          .where(txhash: txn['txhash'])
          .update(status: 'seen', block_number: txn['blockNumber'])
      end
    end

    [:ok, nil]
  end

  # Given a request method, path and payload, make the HTTP request to the info
  # server and return a tagged tupple of result or error
  def request_info_server(method, endpoint, payload = {})
    new_nonce = SelfServer.increment_nonce

    signature = InfoServer.access_signature(method, endpoint, new_nonce, payload)

    uri = URI.parse("#{SERVER_URL}#{endpoint}")
    https = Net::HTTP.new(uri.host, uri.port)
    # https.use_ssl = true
    request_class = case method.upcase
                    when 'POST'
                      Net::HTTP::Post
                    when 'GET'
                      Net::HTTP::Get
                    else
                      return [:invalid_method, nil]
                    end

    req = request_class.new(uri.path,
                            'Content-Type' => 'application/json',
                            'ACCESS-SIGN' => signature,
                            'ACCESS-NONCE' => new_nonce.to_s)
    req.body = { payload: payload }.to_json

    begin
      res = https.request(req)

      result = JSON.parse(res.body).dig('result')

      [:ok, result]
    rescue StandardError
      [:error, nil]
    end
  end

    private

  # Given a string, hash it with the info server secret
  def message_signature(message)
    digest = OpenSSL::Digest.new('sha256')

    OpenSSL::HMAC.hexdigest(digest, SERVER_SECRET, message)
  end

  # Given a request's method, path, nonce and payload, concatenate them
  # to create an unique message for authentication
  def access_message(method, path, nonce, payload)
    "#{method.upcase}#{path}#{payload.to_json}#{nonce}"
  end

  # Like `access_message` but takes a HTTP request
  def request_message(request)
    access_message(
      request.method,
      request.original_fullpath,
      request.headers.fetch('ACCESS-NONCE', '').to_i,
      # This should be params.payload but auto snake case interferes
      request.raw_post.empty? ? request.params.fetch('payload', '')
        : JSON.parse(request.raw_post).fetch('payload', '')
    )
  end
  end

  class InvalidRequest < StandardError; end
end
