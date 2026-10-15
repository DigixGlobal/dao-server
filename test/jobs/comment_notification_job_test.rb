# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class CommentNotificationJobTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup :email_fixture

  test 'notifies the project author when another user comments' do
    proposal = create(:proposal)
    commenter = create(:user)
    comment = nil

    InfoApi.stub(
      :list_proposals,
      [:ok, [{ 'proposal_id' => proposal.proposal_id, 'title' => 'Project Title' }]]
    ) do
      assert_emails 1 do
        comment = create(
          :comment,
          parent: proposal.comment,
          stage: proposal.stage,
          user: commenter,
          body: '<p>Hello <strong>project owner</strong></p>'
        )
      end
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [proposal.user.email], email.to
    assert_equal 'New comment on your DigixDAO project', email.subject
    assert_equal 'text/plain', email.mime_type
    assert_includes email.body.decoded, 'Project Title'
    assert_includes email.body.decoded, commenter.display_name
    assert_includes email.body.decoded, comment.created_at.utc.iso8601
    assert_includes email.body.decoded, 'Hello project owner'
    assert_not_includes email.body.decoded, '<strong>'
  end

  test 'notifies the project author when a participant replies in the thread' do
    proposal = create(:proposal)
    parent = create(
      :comment,
      parent: proposal.comment,
      stage: proposal.stage,
      user: proposal.user
    )

    InfoApi.stub(
      :list_proposals,
      [:ok, [{ 'proposal_id' => proposal.proposal_id, 'title' => 'Project Title' }]]
    ) do
      assert_emails 1 do
        create(:comment, parent: parent, stage: proposal.stage)
      end
    end

    assert_equal [proposal.user.email], ActionMailer::Base.deliveries.last.to
  end

  test 'does not notify the project author about their own comment' do
    proposal = create(:proposal)

    assert_no_emails do
      create(
        :comment,
        parent: proposal.comment,
        stage: proposal.stage,
        user: proposal.user
      )
    end
  end

  test 'does not notify for comments outside a proposal thread' do
    parent = create(:comment)

    assert_no_emails do
      create(:comment, parent: parent, stage: parent.stage)
    end
  end
end
