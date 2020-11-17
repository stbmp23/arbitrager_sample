# frozen_string_literal: true

module Arbitrager
  class Position
    attr_reader :ask, :bid, :ask_balance, :bid_balance, :threshold_jpy, :threshold_btc

    # initialize
    #
    # @param [Arbitrager::Board::Position] ask
    # @param [Arbitrager::Board::Position] bid
    def initialize(ask, bid)
      @ask = ask
      @bid = bid
      @ask.target_volume = target_volume
      @bid.target_volume = target_volume
      @ask.action = :ask
      @bid.action = :bid
      @ask_balance = Arbitrager.balancer.find(ask.broker_code)
      @bid_balance = Arbitrager.balancer.find(bid.broker_code)
      @threshold_jpy = Settings.balancer.threshold.jpy
      @threshold_btc = Settings.balancer.threshold.btc
    end

    # 目標利益(差分)
    def target_profit
      bid.price - ask.price
    end

    # 目標獲得数量
    def target_volume
      @target_volume ||= [
        ask.volume,
        bid.volume,
        Settings.max_size,
      ].min
    end

    # 目標利益(JPY)
    def target_profit_price
      bid.exchange_price - ask.exchange_price
    end

    # 目標利益率(％)
    # 取引を行うとどれくらいの利益を得ることができるのか
    def target_profit_percent
      mid_price = (ask.price + bid.price) / 2.0
      (target_profit / (mid_price * target_volume)) * 100.0
    end

    # 取引可能かどうか(Ask:買い)
    # 1: 資産(JPY) > 閾値
    # 2: 資産(JPY) > 購入金額
    #
    # @return [true, false]
    def can_ask?
      ask_balance.jpy > threshold_jpy && ask_balance.jpy > ask.exchange_price
    end

    # 取引可能かどうか(Bid:売り)
    # 1: 資産(BTC) > 閾値
    # 2: 資産(BTC) > 売却数量
    #
    # @return [true, false]
    def can_bid?
      bid_balance.btc > threshold_btc && bid_balance.btc > target_volume
    end

    # 目標収益が取引可能なものになっているか
    #
    # @return [true, false]
    def check_target_profit_ok?
      target_profit_price > Settings.min_target_profit
    end

    # 目標収益率が取引可能なものになっているか
    #
    # @return [true, false]
    def check_target_profit_percent_ok?
      target_profit_percent > Settings.min_target_profit_percent
    end

    # 目標取引量が取引可能なものになっているか
    #
    # @return [true, false]
    def check_target_volume_ok?
      Settings.min_size <= target_volume && target_volume <= Settings.max_size
    end

    # 取引可能かどうか
    #
    # @return [true, false]
    def can_exchange?
      can_ask? &&
        can_bid? &&
        check_target_profit_ok? &&
        check_target_profit_percent_ok? &&
        check_target_volume_ok?
    end
  end
end
