# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'
require 'database_cleaner'

require 'info_server'

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/app/channels/'
  add_filter '/app/controllers/overrides'
  add_filter '/app/jobs/'
  add_filter '/app/mailers/'
  add_filter '/bin/'
end
puts 'Starting SimpleCov'

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    setup :database_fixture

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

      put authorization_path, params: params

      ::JSON.parse(@response.body)
            .fetch('result', {})
            .slice('access-token', 'client', 'uid')
    end

    def create_auth_user(**kwargs)
      key = Eth::Key.new
      user = create(:user, address: key.address, **kwargs)

      [user, auth_headers(key), key]
    end

    def database_fixture
      Transaction.delete_all
      CommentLike.delete_all
      ProposalLike.delete_all
      Proposal.delete_all
      Comment.delete_all
      CommentHierarchy.delete_all
      Challenge.delete_all
      User.delete_all
      Nonce.delete_all

      create(:server_nonce, server: Rails.configuration.nonces['info_server_name'])
      create(:server_nonce, server: Rails.configuration.nonces['self_server_name'])
    end

    def info_get(path, payload: {}, headers: {}, **kwargs)
      info_path = "#{path}?payload=#{payload}"

      info_headers = info_server_headers('GET', info_path, payload)

      get(info_path,
          headers: headers.merge(info_headers),
          **kwargs)
    end

    def info_post(path, payload: {}, headers: {}, **kwargs)
      info_headers = info_server_headers('POST', path, payload)

      post(path,
           params: { payload: payload }.to_json,
           headers: headers.merge(info_headers),
           env: { 'RAW_POST_DATA' => { payload: payload }.to_json },
           **kwargs)
    end

    def info_put(path, payload: {}, headers: {}, **kwargs)
      info_headers = info_server_headers('PUT', path, payload)

      put(path,
          params: { payload: payload }.to_json,
          headers: headers.merge(info_headers),
          env: { 'RAW_POST_DATA' => { payload: payload }.to_json },
          **kwargs)
    end
  end
end
