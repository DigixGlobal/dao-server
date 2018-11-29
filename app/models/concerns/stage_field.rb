# frozen_string_literal: true

module StageField
  extend ActiveSupport::Concern
  included do
    enum stage: { idea: 1, draft: 2 }
  end
end
