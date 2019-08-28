# frozen_string_literal: true

require 'faker'

static_nonce = Random.rand(1001..2000)

FactoryBot.define do
  sequence(:transaction_object) do |_|
    { 'nonce' => Random.rand(1..1000) }
  end
  sequence(:fixed_transaction_object) do |_|
    { 'nonce' => static_nonce }
  end
  sequence(:signed_transaction) { |_| SecureRandom.hex(32) }
  sequence(:id) { |_| SecureRandom.hex(32) }

  factory :watching_transaction, class: 'WatchingTransaction' do
    txhash { generate(:txhash) }
    transaction_object { generate(:fixed_transaction_object) }
    signed_transaction { generate(:signed_transaction) }
    association :user, factory: :user
  end

  factory :watch_transaction, class: 'Hash' do
    transactionHash { generate(:txhash) }
    transactionObject { JSON.generate(generate(:transaction_object)) }
    signedTransaction { generate(:signed_transaction) }

    factory :watch_transaction_resend do
      id { generate(:id) }
      transactionObject { JSON.generate(generate(:fixed_transaction_object)) }
    end
  end
end
