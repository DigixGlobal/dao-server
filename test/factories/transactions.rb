# frozen_string_literal: true

FactoryBot.define do
  sequence(:title) { |n| "title-#{n}" }
  sequence(:txhash) { |n| "tx-#{n}" }
  sequence(:block_number) { |n| n }

  factory :transaction, class: 'Transaction' do
    title { generate(:title) }
    txhash { generate(:txhash) }
    block_number { generate(:block_number) }
    association :user, factory: :user
  end
end
