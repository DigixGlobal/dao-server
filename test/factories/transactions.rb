# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  sequence(:title) { |_| Faker::StarWars.quote }
  sequence(:txhash) { |_| Faker::Ethereum.address }
  sequence(:block_number) { |_| SecureRandom.random_number(10_000) }
  sequence(:type) { |_| Transaction.types.keys.sample }

  factory :transaction, class: 'Transaction' do
    title { generate(:title) }
    txhash { generate(:txhash) }
    block_number { generate(:block_number) }
    association :user, factory: :user

    factory :transaction_claim_result do
      transaction_type { |_| 1 }
      project { generate(:address) }
    end
  end

  factory :claim_result_transaction, class: 'Object' do
    title { generate(:title) }
    txhash { generate(:txhash) }
    type { |_| 1 }
    project { generate(:address) }
  end
end
