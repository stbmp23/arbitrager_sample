# frozen_string_literal: true

module Arbitrager
  module Board
    class Position
      attr_reader :broker_code, :price, :volume, :broker
      attr_accessor :target_volume, :action

      # initialize
      #
      # @param [Symbol] broker_code 取引所コード
      # @param [Float] price 板の価格(best_ask or best_bid)
      # @param [Float] volume 板の数量(best_ask_volume or best_bid_volume)
      def initialize(broker_code, price, volume)
        @broker_code = broker_code
        @broker = Arbitrager.brokers.get(@broker_code)
        @price = price
        @volume = volume
      end

      # 取引価格(手数料抜き)
      #
      # @return [Float]
      def exchange_base_price
        price * target_volume
      end

      # 取引価格(手数料込み)
      #
      # @return [Float]
      def exchange_price
        case action
        when :ask
          exchange_base_price + commission
        when :bid
          exchange_base_price - commission
        else
          raise "please set action. :ask or :bid"
        end
      end

      # 手数料
      #
      # @return [Float]
      def commission
        exchange_base_price * (broker.commission_percent / 100)
      end
    end
  end
end
