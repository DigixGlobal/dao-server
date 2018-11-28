# frozen_string_literal: true

class Comment < ActiveRecord::Base
  include Discard::Model
  has_closure_tree
end
