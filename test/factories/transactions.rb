# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  sequence(:title) { |_| Faker::StarWars.quote }
  sequence(:txhash) { |_| "0x#{Faker::Ethereum.address}" }
  sequence(:block_number) { |_| SecureRandom.random_number(10_000) }

  factory :transaction, class: 'Transaction' do
    title { generate(:title) }
    txhash { generate(:txhash) }
    block_number { generate(:block_number) }
    association :user, factory: :user
  end
end
