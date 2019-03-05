# frozen_string_literal: true

FactoryBot.define do
  sequence(:proposal_stage) { |_| Proposal.stages.keys.sample }

  factory :proposal, class: 'Proposal' do
    proposal_id { generate(:address) }
    stage { generate(:proposal_stage) }
    association :user, factory: :user_with_kyc

    before(:create) do |proposal, _evaluator|
      unless proposal.comment
        proposal.comment = create(:comment, stage: proposal.stage)
      end
    end

    factory :proposal_with_comments do
      transient do
        comment_count { 3 }
        comment_depth { 3 }
        comment_ratio { 67 }
      end
      after(:create) do |proposal, evaluator|
        comment_count = evaluator.comment_count
        comment_depth = evaluator.comment_depth
        comment_ratio = evaluator.comment_ratio

        comments = create_list(:comment, comment_count, parent: proposal.comment)
        more_comments = comments
        depth = 0

        until more_comments.empty? || (depth >= comment_depth)
          new_comments = []

          more_comments.each do |comment|
            create_list(
              :comment,
              comment_count,
              stage: proposal.stage,
              parent: comment
            ).each do |reply|
              new_comments.push(reply) if Random.rand(100) >= comment_ratio
            end
          end

          depth += 1
          more_comments = new_comments
        end
      end
    end

    factory :proposal_with_likes do
      transient do
        like_count { 40 }
      end

      after(:create) do |proposal, evaluator|
        like_count = evaluator.like_count

        count = Random.rand(1..like_count)
        count.times do
          create(:proposal_like, proposal: proposal)
        end

        proposal.update(likes: count)
      end
    end
  end

  factory :create_proposal, class: 'Hash' do
    proposal_id { generate(:address) }
    proposer { generate(:address) }
  end
end
