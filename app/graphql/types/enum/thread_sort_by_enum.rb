# frozen_string_literal: true

module Types
  module Enum
    class ThreadSortByEnum < Types::Base::BaseEnum
      value 'LATEST', 'Sort in descending creation time',
            value: 'latest'
      value 'OLDEST', 'Sort in ascending creation time',
            value: 'oldest'
    end
  end
end
