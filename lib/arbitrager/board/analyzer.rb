# frozen_string_literal: true

require 'arbitrager/board/bit_flyer'
require 'arbitrager/board/coin_check'
require 'arbitrager/board/zaif'

module Arbitrager
  module Board
    class Analyzer
      def boards
        @boards ||= Arbitrager.boards.select { |board| board.broker.enable? }
      end

      # 各取引所の板情報の更新をする
      #
      # @return [true, false]
      def refresh
        result = Parallel.map(boards, in_threads: boards.size) do |board|
          result = board.refresh
          raise Parallel::Break unless result
          result
        end

        return false if result.nil?

        # 板情報更新後は各計算結果もクリアにする
        @target_position = nil
        @boards = nil

        true
      rescue Faraday::Error::TimeoutError => e
        Arbitrager.logger.error(e)
        return false
      end

      # 板情報の更新を成功するまで行う
      def refresh!
        until refresh
          Arbitrager.logger.info('板情報の更新に失敗しました。3秒後にもう一度実行します。')
          sleep 3
        end
      end

      # 最大収益を出せる組み合わせを探す
      #
      # @return [Arbitrager::Position]
      def target_position
        return @target_position if @target_position

        positions = []

        boards.permutation(2) do |boards|
          # 購入対象となりえないものを除外する
          position = Arbitrager::Position.new(boards[0].best_ask, boards[1].best_bid)
          positions << position if position.can_exchange?
        end

        @target_position = positions.max { |a, b| a.target_profit_price <=> b.target_profit_price }
      end

      # Best Ask
      def best_ask
        target_position.ask
      end

      # Best Bid
      def best_bid
        target_position.bid
      end

      # ネットエクスポージャー
      def target_net_exposure
        boards.inject(0) { |sum, board| sum += board.net_exposure }
      end

      # 取引できそうか確認する
      def can_exchange?
        # ネットエクスポージャー値が設定値以下の場合はシステムを停止する
        if target_net_exposure > Settings.max_net_exposure
          raise Arbitrager::Error::NetExposureError.new
        end

        target_position.nil? ? false : true
      end

      # 板の解析情報
      def info
        message = "Analyzed Data\n"
        message += "板情報 ----\n"
        boards.each do |board|
          message += "#{board.broker.code}:\n"
          message += "best_ask(売り板): [#{board.best_ask.price}, #{board.best_ask.volume}], "
          message += "best_bid(買い板): [#{board.best_bid.price}, #{board.best_bid.volume}]\n"
        end

        message += "価格差 ----\n"
        boards.permutation(2) do |boards|
          pos = Arbitrager::Position.new(boards[0].best_ask, boards[1].best_bid)
          message += "#{pos.bid.broker_code} BestBid(買い板) - #{pos.ask.broker_code} BestAsk(売り板): #{pos.bid.price} - #{pos.ask.price} = #{pos.bid.price - pos.ask.price}\n"
        end

        message += "利益計算 ----\n"
        boards.permutation(2) do |boards|
          pos = Arbitrager::Position.new(boards[0].best_ask, boards[1].best_bid)
          message += "#{pos.bid.broker_code} (売り) - #{pos.ask.broker_code} (買い): #{pos.bid.exchange_price} - #{pos.ask.exchange_price} = #{pos.target_profit_price}\n"
        end

        message += "結果 ----\n"
        if target_position.present?
          message += "best_ask(売り): [#{best_ask.price}, #{best_ask.volume}] (#{best_ask.broker.name})\n"
          message += "best_bid(買い): [#{best_bid.price}, #{best_bid.volume}] (#{best_bid.broker.name})\n"
          message += "Target Profit(目標利益): #{target_position.target_profit}\n"
          message += "Target Size(目標取引量): #{target_position.target_volume}\n"
          message += "Target Profit Percent(推定利益率): #{sprintf('%.2f', target_position.target_profit_percent)}%\n"
          message += "Net Exposure(ネットエクスポージャー): #{target_net_exposure}\n"
          message += "====================================================================\n"
          message += "(買い)#{best_ask.broker.name}: #{best_ask.price} * #{target_position.target_volume}\n"
          message += "(売り)#{best_bid.broker.name}: #{best_bid.price} * #{target_position.target_volume}\n"
          message += "--------\n"
          message += "獲得可能利益: #{target_position.bid.exchange_price} - #{target_position.ask.exchange_price} = #{sprintf('%.3f', target_position.target_profit_price)}\n"
        else
          message += "取引可能なものがありませんでした"
        end

        Arbitrager.logger.debug(message)
      end
    end
  end
end
