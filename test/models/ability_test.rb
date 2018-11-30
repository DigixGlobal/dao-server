# frozen_string_literal: true

require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test 'user proposal abilities should work' do
    this_proposal = create(:proposal)
    user_ability = Ability.new(this_proposal.user)

    assert user_ability.can?(:read, Proposal)
    assert user_ability.can?(:create, Proposal)
    assert user_ability.can?(:delete, this_proposal)

    other_proposal = create(:proposal)
    other_ability = Ability.new(other_proposal.user)

    assert other_ability.can?(:delete, other_proposal)
    assert other_ability.cannot?(:delete, this_proposal)
  end

  test 'user proposal comments abilities should work' do
    this_comment = create(:comment)
    user_ability = Ability.new(this_comment.user)

    assert user_ability.can?(:read, Comment)
    assert user_ability.can?(:create, Comment)
    assert user_ability.can?(:delete, this_comment)

    other_comment = create(:comment)
    other_ability = Ability.new(other_comment.user)

    assert other_ability.can?(:delete, other_comment)
    assert other_ability.cannot?(:delete, this_comment)
  end
end
