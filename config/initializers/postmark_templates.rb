# frozen_string_literal: true

if ActionMailer::Base.postmark_settings[:api_token].present?
  ActionMailer::Base.register_preview_interceptor(PostmarkRails::PreviewInterceptor)
end
