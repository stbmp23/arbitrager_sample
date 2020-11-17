# frozen_string_literal: true

require 'arbitrager/balances/bit_flyer'
require 'arbitrager/balances/coin_check'
require 'arbitrager/balances/zaif'
require 'arbitrager/balances/quoinex'
require 'arbitrager/balances/bit_bank'
require 'arbitrager/balances/btc_box'

module Arbitrager
  class Balancer
    attr_reader :balances

    def initialize
      @balances = []

      Arbitrager.brokers.each do |broker|
        if broker.enable?
          @balances << "Arbitrager::Balances::#{broker.name.classify}".constantize.new
        end
      end
    end

    # 対象の取引所を取得する
    #
    # @param [Symbol] code 取引所コード
    # @return [Arbitrager::Balances]
    def find(code)
      result = balances.find { |balance| balance.broker.code == code }

      if result.blank?
        raise "Not found balance. broker_code: #{code}. Please check settings"
      end

      result
    end

    # 各取引所のJPY, BTCの数量を更新する
    def refresh
      result = Parallel.map(balances, in_threads: balances.size) do |balance|
        result = balance.refresh!
        raise Parallel::Break unless result
        result
      end

      return false if result.nil?

      true
    rescue Faraday::Error::TimeoutError => e
      Arbitrager.logger.error(e)
      return false
    rescue Arbitrager::Error::ApiResponseError => e
      Arbitrager.logger.error(e)
      return false
    end

    # 資産状況を更新する
    def refresh!
      until refresh
        Arbitrager.logger.warn('資産情報の更新に失敗しました。3秒後にもう一度更新を試みます。')
        sleep 3
      end
    end

    # 各取引所のJPY, BTCの数量をチェックする
    def ok?
      start_time = Time.now
      until refresh
        wait_time = Settings.wait_for_balancer_refresh_time
        Arbitrager.logger.info("Balancer.refresh に失敗しました。#{wait_time}秒後にもう一度実行します")
        sleep(wait_time)

        # 一定時間経過しても取得ができない場合は false とみなす
        return false if Time.now - start_time > Settings.balancer.check_wait_time
      end

      # 全ての取引所で偏りがなければ正常とする
      balances.each do |balance|
        return false unless balance.ok?
      end

      true
    end

    # 資産状況を表示する
    def info
      message = "資産状況----\n"

      balances.each do |balance|
        message += "#{balance.broker.code}, JPY: #{balance.jpy}, BTC: #{balance.btc}\n"
      end

      Arbitrager.logger.info(message)
    end

    # 資産状況を保存する
    def save_history(options = {})
      Arbitrager.balancer.balances.each do |balance|
        before_balance = {}
        if options[:before_balances].present?
          before_balance = options[:before_balances].find { |b| b[:broker].id == balance.broker.id }
        end

        Arbitrager::Models::BalanceHistory.create({
          broker_id: balance.broker.id,
          exchange_id: options[:exchange_id],
          jpy: balance.jpy,
          btc: balance.btc,
          before_jpy: before_balance[:jpy] || 0,
          before_btc: before_balance[:btc] || 0,
        })
      end
    end
  end
end
