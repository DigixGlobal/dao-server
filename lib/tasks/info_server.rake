# frozen_string_literal: true

require 'typhoeus'
require 'factory_bot'

namespace :info_server do
  desc 'Info Server Proposal Comment Seeding'
  task comment_seed: :environment do
    FactoryBot.find_definitions

    response = Typhoeus::Request.get(
      'http://localhost:3001/proposals/all',
      headers: { 'Content-Type' => 'application/json' },
      body: { payload: {} }.to_json
    )

    unless response.code == 200
      puts 'Could not fetch data from the info server.'
      exit
    end

    payload = JSON.parse(response.body)
    proposal_ids =
      payload
      .fetch('result')
      .map { |proposal| proposal.fetch('proposalId') }

    addresses =
      payload
      .fetch('result')
      .map { |proposal| proposal.fetch('proposer') }

    proposals = Proposal.where(proposal_id: proposal_ids).to_a
    users = User.where(address: addresses).to_a

    if proposals.empty?
      puts 'No proposals found. Sync up with info server first.'
      exit
    end

    puts 'Start seeding proposal comment'
    proposals.each do |proposal|
      Proposal.stages.keys.map do |stage|
        puts "Seeding #{proposal.proposal_id} #{stage}"
        eval_build_dsl(proposal.comment, users, random_build_dsl(stage))
      end
    end
  end
end

def random_build_dsl(stage)
  s = stage
  case Random.rand(1..1)
  when 1
    [nil, nil,
     [s, 0,
      [s, 2,
       [s, 4],
       [s, 4],
       [s, 5],
       [s, nil],
       [s, nil]],
      [s, 2],
      [s, 3],
      [s, nil],
      [s, nil],
      [s, nil],
      [s, nil],
      [s, nil]],
     [s, 0],
     [s, 1],
     [s, nil],
     [s, nil],
     [s, nil],
     [s, nil],
     [s, nil],
     [s, nil],
     [s, nil],
     # Load More
     [s, 2,
      [s, nil,
       [s, nil,
        [s, nil,
         [s, nil,
          [s, nil,
           [s, nil,
            [s, nil,
             [s, nil,
              [s, nil,
               [s, nil]]]]]]]]]]],
     [s, 2],
     [s, 3],
     [s, nil],
     [s, nil]]
  end
end

def eval_build_dsl(parent_comment, users, dsl)
  return [] if dsl.empty?

  stage = dsl[0]
  user_index = dsl[1]
  child_dsls = dsl.slice(2..-1)

  user =
    if user_index.nil?
      users.sample
    else
      index = user_index % users.size
      users.fetch(index)
    end

  comment =
    if stage.nil?
      parent_comment
    else
      FactoryBot.create(
        :comment,
        stage: stage,
        parent: parent_comment,
        user: user
      )
    end

  children = (child_dsls || [])
             .map { |child_dsl| eval_build_dsl(comment, users, child_dsl) }

  [comment.slice(:id, :stage, :parent_id, :user).to_h].concat(children)
end
