# frozen_string_literal: true

class NotificationMailerPreview < ActionMailer::Preview
  def kyc_submitted
    NotificationMailer.with(kyc: Kyc.all.sample).kyc_submitted
  end

  def kyc_approved
    NotificationMailer.with(kyc: Kyc.all.sample).kyc_approved
  end

  def kyc_rejected
    NotificationMailer.with(kyc: Kyc.all.sample).kyc_rejected
  end

  def project_created
    NotificationMailer.with(proposal: Proposal.all.sample).project_created
  end

  def project_endorsed
    NotificationMailer.with(proposal: Proposal.all.sample).project_endorsed
  end
end
