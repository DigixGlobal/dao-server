# frozen_string_literal: true

require 'test_helper'

class ApplicationMailerTest < ActiveSupport::TestCase
  setup :email_fixture

  test 'should log errors' do
    proposal = create(:proposal)
    proposal.reload
    Kyc.delete_all

    assert_nil proposal.user.kyc

    assert_nil NotificationMailer.with(proposal: proposal).project_created.deliver_now
  end
end
