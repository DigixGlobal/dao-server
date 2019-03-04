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
end
