# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV['POSTMARK_FROM']
  layout 'mailer'

  rescue_from Postmark::InvalidApiKeyError, with: :log_mail_error
  rescue_from Postmark::TimeoutError, with: :log_mail_error
  rescue_from Postmark::InternalServerError, with: :log_mail_error
  rescue_from Postmark::HttpClientError, with: :log_mail_error
  rescue_from Postmark::InactiveRecipientError, with: :log_mail_error
  rescue_from Postmark::ApiInputError, with: :log_mail_error
  rescue_from Postmark::Error, with: :log_mail_error
  rescue_from ActionView::Template::Error, with: :log_mail_error
  rescue_from Exception, with: :log_error

  private

  def log_error(error)
    Rails.logger.info('Application error when sending an email')
    Rails.logger.info(error)
  end

  def log_mail_error(error)
    Rails.logger.info("Error when sending #{message} to #{error.recipients.join(', ')}")
    Rails.logger.info(error)
  end
end
