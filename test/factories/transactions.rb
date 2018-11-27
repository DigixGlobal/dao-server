# frozen_string_literal: true

FactoryBot.define do
  sequence(:title) { |n| "title-#{n}" }
  sequence(:txhash) { |n| "tx-#{n}" }
  sequence(:blockNumber) { |n| n }

  factory :transaction, class: 'Transaction' do
    title { generate(:title) }
    txhash { generate(:txhash) }
    blockNumber { generate(:blockNumber) }
    association :user, factory: :user
  end
end
