# frozen_string_literal: true

require 'test_helper'

require 'event_handler'

class EventHandlerTest < ActiveSupport::TestCase
  setup :email_fixture

  test 'project created event should be handled' do
    proposal = create(:proposal)
    ok, = EventHandler.handle_event(
      event_type: 1,
      proposer: proposal.user.address,
      proposal_id: proposal.proposal_id
    )

    assert_equal :ok, ok,
                 'should work'

    assert_emails 1

    mail = ActionMailer::Base.deliveries.last

    assert_equal proposal.user.email, mail.to.first,
                 'email should be sent to the proposer'
    assert_equal 'Your project was successfully created', mail.subject,
                 'subject should be correct'
  end

  test 'project endorsed event should be handled' do
    proposal = create(:proposal)
    ok, = EventHandler.handle_event(
      event_type: 2,
      proposer: proposal.user.address,
      proposal_id: proposal.proposal_id
    )

    assert_equal :ok, ok,
                 'should work'

    assert_emails 1

    mail = ActionMailer::Base.deliveries.last

    assert_equal proposal.user.email, mail.to.first,
                 'email should be sent to the proposer'
    assert_equal 'Your project was successfully endorsed', mail.subject,
                 'subject should be correct'
  end

  test 'should fail safely' do
    invalid_event_type, = EventHandler.handle_event({})

    assert_equal :invalid_event_type, invalid_event_type,
                 'should fail if the event cannot be handled'

    proposal = create(:proposal)
    proposal_not_found, = EventHandler.handle_event(
      event_type: 1,
      proposer: proposal.user.address,
      proposal_id: 'NON_EXISTENT_ID'
    )

    assert_equal :proposal_not_found, proposal_not_found,
                 'should fail if the proposal does not exist'
  end
end
