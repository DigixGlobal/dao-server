# frozen_string_literal: true

require 'test_helper'

class ProposalFlowsTest < ActionDispatch::IntegrationTest
  setup :database_fixture

  test 'create new proposal should work' do
    post transactions_confirmed_path,
         params: { payload: transactions }.to_json,
         headers: info_server_headers(
           'POST',
           transactions_confirmed_path,
           transactions
         )
  end
end
