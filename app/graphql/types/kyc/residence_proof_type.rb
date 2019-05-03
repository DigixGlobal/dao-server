# frozen_string_literal: true

module Types
  module Kyc
    class ResidenceProofType < Types::Base::BaseObject
      description 'Customer residence proof for KYC submission'

      field :residence, Types::Kyc::AddressType,
            null: false,
            description: 'Current residential address of the customer'
      field :type, Types::Enum::ResidenceProofTypeEnum,
            null: false,
            description: 'Kind of image presented as proof'
      field :image, Types::ImageType,
            null: true,
            description: <<~EOS
              Image of the residence proof.
               It is possible for this to be `null` after submitting
              since file storage is asynchronous, so be careful with the mutation.
              Howver, it should be a valid object in practice.
            EOS

      def image
        encode_attachment(object[:image].attachment)
      end

      private

      def encode_attachment(attachment)
        return nil unless attachment && (blob = attachment.blob)

        {
          filename: blob.filename,
          file_size: blob.byte_size,
          content_type: blob.content_type,
          data_url: "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
        }
      end
    end
  end
end
