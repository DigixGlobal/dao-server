# frozen_string_literal: true

FactoryBot.define do
  sequence(:challenge) { |_| "A new challenger has appeared #{SecureRandom.hex}" }

  factory :user_challenge, class: 'Challenge' do
    challenge { generate(:challenge) }
    association :user, factory: :user
  end
end
