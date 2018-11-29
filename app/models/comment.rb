# frozen_string_literal: true

class Comment < ActiveRecord::Base
  include StageField
  include Discard::Model
  has_closure_tree
  belongs_to :user

  belongs_to :proposal

  validates :body,
            presence: true,
            length: { maximum: 10_000 }
  validates :stage,
            presence: true
  validates :user,
            presence: true
  validates :proposal,
            presence: true
end
