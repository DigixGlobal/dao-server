# frozen_string_literal: true

module Types
  class ImageType < Types::BaseObject
    description 'Image used for KYC such as jpegs or pngs'

    field :file_name, String,
          null: false,
          description: 'File name of the image'
    field :file_size, Integer,
          null: false,
          description: 'File size of the image'
    field :content_type, String,
          null: false,
          description: 'Content type of the image such as `application/png`'
  end
end
