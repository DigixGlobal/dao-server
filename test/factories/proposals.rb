# frozen_string_literal: true

FactoryBot.define do
  sequence(:proposal_id) { |_| Random.rand(100..1000) }

  factory :proposal, class: 'Proposal' do
    association :proposal, factory: :user
  end

  factory :info_proposal, class: 'Object' do
    proposal_id { generate(:proposal_id) }
    proposer { generate(:address) }
  end
end
