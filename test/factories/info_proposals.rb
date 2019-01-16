# frozen_string_literal: true

FactoryBot.define do
  sequence(:boolean) { |_| [true, false].sample }
  sequence(:amount) { |n| n }
  sequence(:vote_count, &:to_s)
  sequence(:voting_stage)  { |_| ['draftVoting'].sample }

  sequence(:description) { |n| "description-#{n}" }
  sequence(:detail) { |n| "detail-#{n}" }
  sequence(:milestone) { |n| [-1, n].sample }
  sequence(:doc) { |_| '???' }
  sequence(:ipfs_address) { |_| Eth::Key.new.address.downcase }
  sequence(:ipfs_hash) { |_| Eth::Key.new.address.downcase }
  sequence(:unix_timestamp) { |_| DateTime.now.to_time.to_i }

  factory :info_milestone, class: 'Object' do
    title { generate(:title) }
    description { generate(:description) }
  end

  factory :info_dijix_object, class: 'Object' do
    title { generate(:title) }
    description { generate(:description) }
    details { generate(:detail) }
    milestone { build_list(:info_milestone, Random.rand(1..3)) }
    images { build_list(:ipfs_hash, Random.rand(1..3)) }
  end

  factory :info_proposal_version, class: 'Object' do
    doc_ipfs_hash { generate(:ipfs_address) }
    created { generate(:unix_timestamp) }
    final_reward { generate(:amount) }
    total_funding { generate(:amount) }
    more_docs { build_list(:ipfs_hash, 0) }
    milestone_fundings { [generate(:amount), generate(:amount)] }
  end

  factory :info_draft_voting, class: 'Object' do
    start_time { generate(:unix_timestamp) }
    voting_deadline { generate(:unix_timestamp) }
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

  factory :info_proposal, class: 'Object' do
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
    # TODO: Resolve entities on dao and info server merge
    # proposal_versions { build_list(:info_proposal_version, 3) }
    # current_voting_round { generate(:current_voting_round) }
    # draft_voting { generate(:info_draft_voting) }
    voting_stage { generate(:voting_stage) }
  end
end
