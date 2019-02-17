# frozen_string_literal: true

FactoryBot.define do
  sequence(:server) { |n| "server-#{n}" }
  sequence(:nonce) { |n| n }

  factory :server_nonce, class: 'Nonce' do
    server { generate(:server) }
    nonce { generate(:nonce) }
  end
end
