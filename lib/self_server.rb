# frozen_string_literal: true

class SelfServer
  SERVER_NAME = Rails.configuration.nonces['self_server_name']

  class << self
    def current_nonce
      Nonce.find_by(server: SERVER_NAME).nonce
    end

    def increment_nonce
      nonce = Nonce.find_by(server: SERVER_NAME)

      incremented_nonce = nonce.nonce + 1
      nonce.update(nonce: incremented_nonce)

      incremented_nonce
    end
  end
end
