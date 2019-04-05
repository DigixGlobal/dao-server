# frozen_string_literal: true

require 'ipaddr'

module Resolvers
  class AppUserResolver < Resolvers::Base
    type Types::User::AppUserType, null: true

    WHITELIST_IPS = ENV.fetch('WHITELIST_IPS') { '' }

    def resolve
      ip_address = context[:ip_address]

      is_unavailable = if check_whitelist?(ip_address)
                         false
                       else
                         check_country?(ip_address)
                       end

      { is_unavailable: is_unavailable }
    end

    private

    def check_country?(ip_address)
      data = Rails.configuration.country_ips.get(ip_address)

      if data
        code = data.dig('country', 'iso_code') ||
               data.dig('continent', 'code') ||
               ''

        Rails.configuration.countries
             .select { |country| country['blocked'] }
             .map { |country| country['value'] }
             .member?(code)
      else
        false
      end
    rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
      false
    end

    def check_whitelist?(ip_address)
      return false unless ip_address && !ip_address.empty?

      client_ip = IPAddr.new(ip_address)

      whitelist_ips = Rails.configuration.ips['whitelist_ips'] +
                      WHITELIST_IPS.strip.split(',')

      whitelist_ips
        .map(&:strip)
        .any? do |raw_ip|
        IPAddr.new(raw_ip).include?(client_ip)
      end
    end
  end
end
