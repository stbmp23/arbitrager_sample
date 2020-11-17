# frozen_string_literal: true

require 'arbitrager/board/position'

module Arbitrager
  module Board
    class Quoinex
      attr_reader :broker, :client

      def initialize
        @broker = Arbitrager.brokers.quoinex
        @client = Arbitrager.clients.quoinex
      end

      # 板情報の更新を行う
      #
      # @return [true, false] 板情報の更新に成功した場合 true
      def refresh
        response = client.order_books
        return false unless response.valid?
        board = response.params

        @asks = board['sell_price_levels']
        @bids = board['buy_price_levels']

        @best_ask = @asks.min{|a, b| a[0].to_i <=> b[0].to_i }
        @best_bid = @bids.max{|a, b| a[0].to_i <=> b[0].to_i }

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
        Arbitrager::Board::Position.new(broker.code, @best_ask[0].to_f, @best_ask[1].to_f)
      end

      # ベストビッド
      #
      # @return [Arbitrager::Board::Position]
      def best_bid
        Arbitrager::Board::Position.new(broker.code, @best_bid[0].to_f, @best_bid[1].to_f)
      end

      # ネットエクスポージャー
      #
      # @return [Float]
      def net_exposure
        @bids.inject(0){|sum, v| sum += v[1].to_f }
        - @asks.inject(0){|sum, v| sum += v[1].to_f }
      end
    end
  end
end
