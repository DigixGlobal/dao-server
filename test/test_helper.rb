# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'info_server'

class ActiveSupport::TestCase
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
end
