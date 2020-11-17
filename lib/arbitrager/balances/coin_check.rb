# frozen_string_literal: true

require 'arbitrager/balances/concern'

module Arbitrager
  module Balances
    class CoinCheck
      include Arbitrager::Balances::Concern

      attr_accessor :jpy, :btc
      attr_reader :broker, :client

      CURRENCY_CODE_JPY = 'jpy'
      CURRENCY_CODE_BTC = 'btc'

      def initialize
        @broker = Arbitrager.brokers.coincheck
        @client = Arbitrager.clients.coincheck
        @threshold_jpy = Settings.balancer.threshold.jpy
        @threshold_btc = Settings.balancer.threshold.btc
      end

      # 資産状況の更新を行う
      #
      # @return [true, false] 資産状況の更新に成功した場合 true
      def refresh
        response = client.get_balance
        return false unless response.valid?
        balance = response.params

        @jpy = balance[CURRENCY_CODE_JPY].to_f
        @btc = balance[CURRENCY_CODE_BTC].to_f

        true
      rescue Faraday::Error::TimeoutError => e
        Arbitrager.logger.error(e)
        return false
      rescue Arbitrager::Error::ApiResponseError => e
        Arbitrager.logger.error(e)
        return false
      end
    end
  end
end
