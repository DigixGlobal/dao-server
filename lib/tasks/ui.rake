# frozen_string_literal: true

require 'pathname'

def hash_key_paths(obj)
  if obj.is_a?(Hash)
    obj
      .map do |key, value|
      inner_keys = hash_key_paths(value)

      if inner_keys.empty?
        [key]
      else
        inner_keys
          .map { |inner_value| inner_value.nil? ? nil : "#{key}:#{inner_value}" }
          .reject(&:nil?)
      end
    end
      .flatten
      .sort
  else
    []
  end
end

def hash_key_values(obj)
  if obj.is_a?(Hash)
    obj
      .map do |key, value|

      inner_values = hash_key_values(value)

      inner_values
        .map { |inner_value| "#{key}:#{inner_value}" }
    end
      .flatten
      .sort
  else
    [obj]
  end
end

namespace :ui do
  desc 'UI tasks for DAO Governance'
  task generate_translations: :environment do
    mapping = { 'english' => 'en', 'chinese' => 'cn' }
    base_translation_name = 'english'
    translation_errors = []

    source = Pathname.new(Rails.root.join('config/translations'))
    target = Pathname.new(Rails.root.join('public/translations'))
    translations = source.children.select(&:directory?)

    base_translation = translations.find { |translation| translation.basename.to_s == base_translation_name }

    translations.each do |translation|
      translation_name = translation.basename
      compiled_translation = {}
      compiled_path = target.join("#{mapping[translation_name.to_s]}.json")

      puts "Compiling #{translation_name}"

      translation.glob('*.json').each do |inner_translation|
        base_inner_translation = base_translation.join(inner_translation.basename.to_s)

        key = inner_translation.basename('.json')

        puts "  Checking #{key} translation"

        base_data = JSON.parse(File.read(base_inner_translation))
        inner_data = JSON.parse(File.read(inner_translation))

        different_keys = hash_key_paths(inner_data) - hash_key_paths(base_data)

        unless different_keys.empty?
          printed_keys = different_keys.map { |different_key| "=> #{key}:#{different_key}=DIFFERENT" }.join("\n  ")

          translation_errors << printed_keys

          puts "  Translation #{key} does not match #{base_translation_name}: \n  #{printed_keys}"
        end

        translation_values = hash_key_values(inner_data)

        invalid_interpolations = translation_values
                                 .filter { |value| value.include?('{{') && value.include?('}}') }

        unless invalid_interpolations.empty?
          printed_keys = invalid_interpolations.map { |invalid_key| "=> #{key}:#{invalid_key}=INTERPOLATION" }.join("\n  ")

          translation_errors << printed_keys

          puts "  Translation #{key} does not match #{base_translation_name}: \n  #{printed_keys}"
        end

        puts "Merging #{key}"

        compiled_translation[key] = inner_data
      end

      puts "Writing #{translation_name} to #{compiled_path}"

      File.write(compiled_path, compiled_translation.to_json)
    end

    if translation_errors.empty?
      puts 'Done compiling'
    else
      puts "Done compiling but with #{translation_errors.size} errors"
    end
  end
end
