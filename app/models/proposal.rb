# frozen_string_literal: true

class Proposal < ActiveRecord::Base
  has_many :comments, -> { where(parent_id: nil) }
end
