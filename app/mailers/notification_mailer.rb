# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def kyc_submitted
    @kyc = params[:kyc]

    mail(
      to: @kyc.user.email,
      subject: 'Your KYC submission has been received'
    )
  end

  def kyc_approved
    @kyc = params[:kyc]

    mail(
      to: @kyc.user.email,
      subject: 'Your KYC submission has been approved'
    )
  end

  def kyc_rejected
    @kyc = params[:kyc]

    mail(
      to: @kyc.user.email,
      subject: 'Your KYC submission has been rejected'
    )
  end

  def project_created
    @proposal = params[:proposal]

    mail(
      to: @proposal.user.email,
      subject: 'Your project was successfully created'
    )
  end

  def project_endorsed
    @proposal = params[:proposal]

    mail(
      to: @proposal.user.email,
      subject: 'Your project was successfully endorsed'
    )
  end

  def project_prl_paused
    @proposal = params[:proposal]

    mail(
      to: @proposal.user.email,
      subject: 'Your project funding has been paused by the PRL'
    )
  end

  def project_prl_stopped
    @proposal = params[:proposal]

    mail(
      to: @proposal.user.email,
      subject: 'Your project funding has been stopped by the PRL'
    )
  end

  def project_comment
    @proposal = params[:proposal]
    @proposal_title = params[:proposal_title] || @proposal.proposal_id
    @comment = params[:comment]
    @comment_body = ActionController::Base.helpers.strip_tags(@comment.body)

    mail(
      to: @proposal.user.email,
      subject: 'New comment on your DigixDAO project'
    )
  end

  private

  def log_error(error)
    raise error if action_name == 'project_comment'

    super
  end

  def log_mail_error(error)
    raise error if action_name == 'project_comment'

    super
  end
end
