# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'typhoeus'
require 'rufus-scheduler'

require 'info_server'
require 'self_server'

ENV['TZ'] = 'Asia/Singapore'
daemonize = ARGV[0] == 'daemon'

if daemonize
  Process.daemon
  pid = Process.pid
  File.open('/tmp/pricefeed_scheduler.pid', 'w') do |file|
    file.puts pid
  end
end

scheduler = Rufus::Scheduler.new

scheduler.every '3s' do
  puts 'Cleaning up old challenges'
  nonce = SelfServer.increment_nonce
  signature = InfoServer.access_signature('DELETE', '/authorizations/old', nonce, {})

  response = Typhoeus::Request.delete(
    'http://localhost:3005/authorizations/old',
    headers: {
      'Content-Type' => 'application/json',
      'ACCESS-SIGN' => signature,
      'ACCESS-NONCE' => nonce.to_s
    },
    body: { payload: {} }.to_json
  )

  case response.code
  when 200
    result = JSON.parse(response.body)

    puts "Cleaned up #{result.fetch(:result, 0)} challenges"
  else
    puts 'Failed to cleanup challenges'
  end
rescue Rufus::Scheduler::TimeoutError
  puts 'Cleaning up old challenges took too long.'
end

scheduler.join
