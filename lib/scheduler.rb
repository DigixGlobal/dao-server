# frozen_string_literal: true

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '1d' do
  Rails.logger.info 'Cleaning up old challenges'

  _ok, records = Challenge.cleanup_challenges

  Rails.logger.info "Cleaned up #{records} challenges"
rescue Rufus::Scheduler::TimeoutError
  Rails.logger.info 'Cleaning up old challenges took too long.'
end
