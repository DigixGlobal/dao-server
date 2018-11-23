# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  INFO_SERVER_NAME = Rails.configuration.nonces['info_server_name']

  def info_server_headers(path, payload)
    next_nonce = Nonce.find_by(server: INFO_SERVER_NAME).nonce + 1

    { 'ACCESS-NONCE': next_nonce,
      'ACCESS-SIGN': 'asd' }
  end
end
