# frozen_string_literal: true

FactoryBot.define do
  sequence(:proposal_id) { |_| Random.rand(100..1000) }
  sequence(:proposal_stage) { |_| Proposal.stages.values.sample }

  factory :proposal, class: 'Proposal' do
    stage { generate(:proposal_stage) }
    association :user, factory: :user
  end

  factory :info_proposal, class: 'Object' do
    proposal_id { generate(:proposal_id) }
    proposer { generate(:address) }
  end
end
