# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def as_json(options = {})
    serializable_hash(options)
      .deep_transform_keys! { |key| key.camelize(:lower) }
  end
end
