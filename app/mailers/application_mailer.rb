# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@digixglobal.com'
  layout 'mailer'
end
