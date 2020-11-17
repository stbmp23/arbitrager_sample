# frozen_string_literal: true

require 'arbitrager/board/bit_flyer'
require 'arbitrager/board/coin_check'
require 'arbitrager/board/zaif'
require 'arbitrager/board/quoinex'
require 'arbitrager/board/bit_bank'
require 'arbitrager/board/btc_box'

module Arbitrager
  class Boards < Array
    attr_accessor :bitflyer, :coincheck, :zaif, :quoinex, :bitbank, :btcbox

    def initialize
      arr = super()

      Arbitrager.brokers.each do |broker|
        klass = "Arbitrager::Board::#{broker.name.classify}".constantize.new
        send(:"#{broker.code}=", klass)
        arr << klass
      end
    end
  end
end
