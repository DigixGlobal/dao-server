# frozen_string_literal: true

require 'pathname'

namespace :ui do
  desc 'UI tasks for DAO Governance'
  task generate_translations: :environment do
    mapping = { 'english' => 'en', 'chinese' => 'ch' }

    source = Pathname.new(Rails.root.join('config/translations'))
    target = Pathname.new(Rails.root.join('public/translations'))
    translations = source.children.select(&:directory?)

    translations.each do |translation|
      translation_name = translation.basename
      compiled_translation = {}
      compiled_path = target.join("#{mapping[translation_name.to_s]}.json")

      puts "Compiling #{translation_name}"

      translation.glob('*.json').each do |inner_translation|
        key = inner_translation.basename('.json')

        puts "Merging #{key}"

        compiled_translation[key] = JSON.parse(File.read(inner_translation))
      end

      puts "Writing #{translation_name} to #{compiled_path}"

      File.write(compiled_path, compiled_translation.to_json)
    end

    puts 'Done compiling'
  end
end
