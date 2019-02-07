# frozen_string_literal: true

FactoryBot.define do
  sequence(:boolean) { |_| [true, false].sample }
  sequence(:amount) { |n| n }
  sequence(:vote_count, &:to_s)
  sequence(:voting_stage)  { |_| %w[draftVoting commit reveal].sample }

  sequence(:description) { |n| "description-#{n}" }
  sequence(:detail) { |n| "detail-#{n}" }
  sequence(:milestone) { |n| [-1, n].sample }
  sequence(:doc) { |_| '???' }
  sequence(:ipfs_address) { |_| Eth::Key.new.address.downcase }
  sequence(:ipfs_hash) { |_| Eth::Key.new.address.downcase }
  sequence(:unix_timestamp) { |_| DateTime.now.to_time.to_i }

  factory :info_milestone, class: 'Hash' do
    title { generate(:title) }
    description { generate(:description) }
  end

  factory :info_dijix_object, class: 'Hash' do
    title { generate(:title) }
    description { generate(:description) }
    details { generate(:detail) }
    milestone { attributes_for_list(:info_milestone, Random.rand(1..3)) }
    images { Array.new(Random.rand(1..3)).map { |_| generate(:ipfs_hash) } }
  end

  factory :info_proposal_version, class: 'Hash' do
    doc_ipfs_hash { generate(:ipfs_address) }
    created { generate(:unix_timestamp) }
    final_reward { generate(:amount) }
    total_funding { generate(:amount) }
    more_docs { [] }
    milestone_fundings { [generate(:amount), generate(:amount)] }
    dijix_object { attributes_for(:info_dijix_object) }
  end

  factory :info_voting_round, class: 'Hash' do
    start_time { generate(:unix_timestamp) }
    voting_deadline { generate(:unix_timestamp) }
    commit_deadline { generate(:unix_timestamp) }
    reveal_deadline { generate(:unix_timestamp) }
    total_voter_stake { generate(:vote_count) }
    total_voter_count { generate(:vote_count) }
    yes { generate(:vote_count) }
    no { generate(:vote_count) }
    quorum { generate(:vote_count) }
    quota { generate(:vote_count) }
    claimed { generate(:boolean) }
    passed { generate(:boolean) }
    funded { generate(:boolean) }
  end

  factory :info_proposal, class: 'Hash' do
    proposal_id { generate(:ipfs_address) }
    proposer { generate(:address) }
    endorser { generate(:address) }
    stage { generate(:proposal_stage) }
    time_created { generate(:unix_timestamp) }
    final_version_ipfs_doc { generate(:ipfs_address) }
    prl { generate(:boolean) }
    is_digix { generate(:boolean) }
    claimable_funding { generate(:amount) }
    current_milestone { generate(:amount) }
    proposal_versions { attributes_for_list(:info_proposal_version, 3) }
    current_voting_round { -1 }
    milestones { attributes_for_list(:info_milestone, 3) }
    draft_voting { attributes_for(:info_voting_round) }
    voting_rounds { attributes_for_list(:info_voting_round, 3) }
    voting_stage { generate(:voting_stage) }
  end
end
