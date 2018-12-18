# frozen_string_literal: true

require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

unless defined?(Rails::Console) || File.split($PROGRAM_NAME).last == 'rake'
  s.every '1d' do
    Rails.logger.info 'Cleaning up old challenges'

    _ok, records = Challenge.cleanup_challenges

    Rails.logger.info "Cleaned up #{records} challenges"
  rescue Rufus::Scheduler::TimeoutError
    Rails.logger.info 'Cleaning up old challenges took too long.'
  end
end
