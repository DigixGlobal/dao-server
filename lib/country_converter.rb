# frozen_string_literal: true

require 'json'

# Download from https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
# And covert to JSON like https://csvjson.com/csv2json
File.read('csv.json')

items =
  records
  .map do |record|
    record.slice(
      'continent_code',
      'continent_name',
      'country_iso_code',
      'country_name'
    )
  end
  .map do |item|
    {
      'name' => item['country_name'],
      'value' => item['country_iso_code'],
      'blocked' => false,
      'continent_value' => item['continent_code']
    }
  end
  .reject do
    item['name'] == ''
  end
  .sort_by do |item|
    item['name']
  end

File.write('countries.json', items.to_json)
