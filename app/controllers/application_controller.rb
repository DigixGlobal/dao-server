class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  SERVER_SECRET = ENV.fetch('DAO_INFO_SERVER_SECRET') { 'this-is-a-secret-between-dao-and-info-server' }
  INFO_SERVER_URL = ENV.fetch('INFO_SERVER_URL') { 'http://localhost:3001' }

  private
    def error_response(error='Error')
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
      # https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = {
        'Content-Type' => 'application/json',
        'ACCESS-SIGN' => signature,
        'ACCESS-NONCE' => new_nonce.to_s
      })
      req.body = { payload: payload }.to_json
      puts "req.body is #{req.body}"
      res = https.request(req)
    end

    def increase_self_nonce
      currentNonce = Nonce.find_by(server: 'self')
      incrementedNonce = currentNonce.nonce + 1
      Nonce.update(currentNonce.id, :nonce => incrementedNonce)
      incrementedNonce
    end

end
