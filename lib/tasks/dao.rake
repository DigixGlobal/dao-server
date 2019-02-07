# frozen_string_literal: true

require 'factory_bot'

namespace :dao do
  desc 'Rake tasks for DAO'
  task seed_pending_kycs: :environment do
    FactoryBot.find_definitions

    count = 30

    ActiveRecord::Base.transaction do
      puts "Creating #{count} pending KYCs"

      count.times do
        kyc = FactoryBot.create(:kyc, status: :pending)
        puts "Created a KYC with #{kyc.id}"
      rescue ActiveRecord::RecordInvalid
        # Safe creation
      end
    end
  end
end
