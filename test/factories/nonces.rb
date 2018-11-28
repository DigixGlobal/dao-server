# frozen_string_literal: true

FactoryBot.define do
  sequence(:server) { |n| "Server-#{n}" }
  sequence(:nonce) { |_| Random.rand(100..1000) }

  factory :server_nonce, class: 'Nonce' do
    server { generate(:server) }
    nonce { generate(:nonce) }
  end
end
