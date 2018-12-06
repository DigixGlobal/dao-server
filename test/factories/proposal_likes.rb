# frozen_string_literal: true

FactoryBot.define do
  factory :proposal_like, class: 'ProposalLike' do
    association :user, factory: :user
    association :proposal, factory: :proposal
  end
end
