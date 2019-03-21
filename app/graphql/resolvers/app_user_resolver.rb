# frozen_string_literal: true

module Resolvers
  class AppUserResolver < Resolvers::Base
    type Types::User::AppUserType, null: true

    def resolve
      is_unavailable =
        begin
          data = Rails.configuration.ips.get(context[:ip_address])

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
        rescue IPAddr::AddressFamilyError
          false
        end

      { is_unavailable: is_unavailable }
    end
  end
end
