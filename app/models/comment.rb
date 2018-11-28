# frozen_string_literal: true

class Comment < ActiveRecord::Base
  has_closure_tree
end
