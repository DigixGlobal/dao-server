# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

require 'info_server'

require 'simplecov'
SimpleCov.start 'rails'
puts 'Starting SimpleCov'

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    INFO_SERVER_NAME = Rails.configuration.nonces['info_server_name']

    def info_server_headers(method, path, payload)
      next_nonce = InfoServer.current_nonce + 1

      { 'ACCESS-NONCE': next_nonce,
        'ACCESS-SIGN': InfoServer.access_signature(
          method,
          path,
          next_nonce,
          payload
        ),
        'CONTENT-TYPE': 'application/json' }
    end

    def auth_headers(eth_key)
      user = User.find_by(address: eth_key.address.downcase)
      challenge = create(:user_challenge, user_id: user.id)

      params = {
        address: user.address,
        challenge_id: challenge.id,
        signature: eth_key.personal_sign(challenge.challenge),
        message: challenge.challenge
      }

      post prove_path, params: params

      ::JSON.parse(@response.body)
            .fetch('result', {})
            .slice('access-token', 'client', 'uid')
    end

    def database_fixture
      Transaction.delete_all
      CommentLike.delete_all
      Comment.delete_all
      CommentHierarchy.delete_all
      Proposal.delete_all
      User.delete_all
      Nonce.delete_all

      create(:server_nonce, server: Rails.configuration.nonces['info_server_name'])
      create(:server_nonce, server: Rails.configuration.nonces['self_server_name'])
    end
  end
end
