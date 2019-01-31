# frozen_string_literal: true

module Types
  class ThreadSortByType < Types::BaseEnum
    value 'LATEST', 'Sort in descending creation time',
          value: 'latest'
    value 'OLDEST', 'Sort in ascending creation time',
          value: 'oldest'
  end
end
