# frozen_string_literal: true

class Nonce < ApplicationRecord
  def self.seed
    add_nonce('self', 0)
    add_nonce('infoServer', 0)
  end

  def self.add_nonce(server, nonce)
    return if Nonce.find_by(server: server)
    n = Nonce.new(server: server, nonce: nonce)
    n.save
  end
end
