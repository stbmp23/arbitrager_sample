# frozen_string_literal: true

require 'arbitrager/api/client'
require 'arbitrager/api/bit_flyer'
require 'arbitrager/api/coin_check'
require 'arbitrager/api/zaif'
require 'arbitrager/api/quoinex'
require 'arbitrager/api/bit_bank'
require 'arbitrager/api/btc_box'

module Arbitrager
  class Clients < Array
    attr_accessor :bitflyer, :coincheck, :zaif, :quoinex, :bitbank, :btcbox

    def initialize
      arr = super()

      Arbitrager.brokers.each do |broker|
        send(:"#{broker.code}=", "Arbitrager::Api::#{broker.name.classify}".constantize.new)
        arr << send(broker.code)
      end
    end

    def get(code)
      self.send(code)
    end
  end
end
