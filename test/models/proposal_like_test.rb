# frozen_string_literal: true

require 'test_helper'

class ProposalLikeTest < ActiveSupport::TestCase
  test 'liking a proposal should work' do
    proposal = create(:proposal)
    user = create(:user)

    ok, liked_proposal = Proposal.like(user, proposal)

    assert_equal :ok, ok,
                 'should work'
    assert_equal 1, liked_proposal.likes,
                 'should update likes'

    already_liked, = Proposal.like(user, proposal)

    assert_equal :already_liked, already_liked,
                 'should not allow to re-like'

    other_user = create(:user)

    ok, still_liked_proposal = Proposal.like(other_user, proposal)

    assert_equal :ok, ok,
                 'should work with other users'
    assert_equal 2, still_liked_proposal.likes,
                 'should update likes once more'
  end

  test 'disliking a proposal should work' do
    like = create(:proposal_like)

    ok, unliked_proposal = Proposal.unlike(like.user, like.proposal)

    assert_equal :ok, ok,
                 'should work'
    assert_equal 0, unliked_proposal.likes,
                 'should be unliked'

    not_liked, = Proposal.unlike(like.user, like.proposal)

    assert_equal :not_liked, not_liked,
                 'should not allow to unlike without liking again'

    other_like = create(:proposal_like, proposal: like.proposal)

    ok, still_disliked_proposal = Proposal.unlike(
      other_like.user,
      other_like.proposal
    )

    assert_equal :ok, ok,
                 'should work'
    assert_equal 0, still_disliked_proposal.likes,
                 'should be still unliked'
  end

  test 'comment like should always be updated' do
    proposal = create(:proposal)

    assert_equal 0, proposal.likes,
                 'should have no likes'

    100.times do
      if proposal.likes.zero?
        user = create(:user)

        ok, updated_proposal = Proposal.like(user, proposal)
      else
        case %i[like unlike].sample
        when :like
          user = create(:user)

          ok, updated_proposal = Proposal.like(user, proposal)
        when :unlike
          like = ProposalLike.all.sample

          ok, updated_proposal = Proposal.unlike(like.user, proposal)
        end
      end

      assert_equal :ok, ok,
                   'should always work'

      proposal = updated_proposal
    end

    assert_equal ProposalLike.count, proposal.likes,
                 'likes should be the same'
  end

  test 'concurrency should be handled with comment' do
    proposal = create(:proposal_with_likes, like_count: 5)
    current_likes = proposal.likes
    workers = Random.rand(5..10)

    (1..workers)
      .map { |_| create(:user) }
      .map { |user| Thread.new { Proposal.like(user, proposal) } }
      .map(&:join)

    assert_equal current_likes + workers, proposal.reload.likes,
                 'likes should handle concurrency properly'

    current_likes = proposal.likes

    disliking_users = ProposalLike
                      .all
                      .sample(Random.rand(1..current_likes))
                      .map(&:user)

    disliking_users
      .map { |user| Thread.new { Proposal.unlike(user, proposal) } }
      .map(&:join)

    assert_equal current_likes - disliking_users.size, proposal.reload.likes,
                 'unlikes should handle concurrency properly'
  end
end
