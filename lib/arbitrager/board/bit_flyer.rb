# frozen_string_literal: true

require 'arbitrager/board/position'

module Arbitrager
  module Board
    class BitFlyer
      attr_reader :broker, :client

      def initialize
        @broker = Arbitrager.brokers.bitflyer
        @client = Arbitrager.clients.bitflyer
      end

      # 板情報の更新を行う
      #
      # @return [true, false] 板情報の更新に成功した場合 true
      def refresh
        response = client.order_books
        return false unless response.valid?
        board = response.params

        @asks = board['asks']
        @bids = board['bids']

        @best_ask = @asks.min{|a, b| a['price'].to_i <=> b['price'].to_i }
        @best_bid = @bids.max{|a, b| a['price'].to_i <=> b['price'].to_i }

        true
      rescue Faraday::Error::TimeoutError => e
        Arbitrager.logger.error(e)
        return false
      rescue Arbitrager::Error::ApiResponseError => e
        Arbitrager.logger.error(e)
        return false
      end

      # ベストアスク
      #
      # @return [Arbitrager::Board::Position]
      def best_ask
        price = @best_ask['price'].to_f + Settings.trade_add_price
        Arbitrager::Board::Position.new(broker.code, price, @best_ask['size'].to_f)
      end

      # ベストビッド
      #
      # @return [Arbitrager::Board::Position]
      def best_bid
        price = @best_bid['price'].to_f - Settings.trade_add_price
        Arbitrager::Board::Position.new(broker.code, price, @best_bid['size'].to_f)
      end

      # ネットエクスポージャー
      #
      # @return [Float]
      def net_exposure
        @bids.inject(0){|sum, v| sum += v['size'].to_f }
        - @asks.inject(0){|sum, v| sum += v['size'].to_f }
      end
    end
  end
end
