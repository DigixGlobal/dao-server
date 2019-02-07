# frozen_string_literal: true

class Group < ApplicationRecord
  has_and_belongs_to_many :users

  enum group: { kyc_officer: 'KYC_OFFICER' }

  def self.seed
    groups.each do |_key, value|
      add_group(value)
    end
  end

  def self.add_group(name)
    return if Group.find_by(name: name)

    Group.create(name: name)
  end
end
