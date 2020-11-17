# frozen_string_literal: true

require 'arbitrager/broker/concern'
require 'arbitrager/broker/bit_flyer'
require 'arbitrager/broker/coin_check'
require 'arbitrager/broker/zaif'
require 'arbitrager/broker/quoinex'
require 'arbitrager/broker/bit_bank'
require 'arbitrager/broker/btc_box'

module Arbitrager
  class Brokers < Array
    attr_accessor :key
    attr_reader :bitflyer, :coincheck, :zaif, :quoinex, :bitbank, :btcbox

    def initialize
      @bitflyer = Arbitrager::Broker::BitFlyer.new
      @coincheck = Arbitrager::Broker::CoinCheck.new
      @zaif = Arbitrager::Broker::Zaif.new
      @quoinex = Arbitrager::Broker::Quoinex.new
      @bitbank = Arbitrager::Broker::BitBank.new
      @btcbox = Arbitrager::Broker::BtcBox.new

      super([@bitflyer, @coincheck, @zaif, @quoinex, @bitbank, @btcbox])
    end

    # コードから取得する
    #
    # @param [Symbol] broker_code 取引所コード
    # @return [Arbitrager::Brokers::Broker]
    def get(broker_code)
      send(broker_code)
    end
  end
end
