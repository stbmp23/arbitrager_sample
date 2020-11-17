# frozen_string_literal: true

require 'arbitrager/balances/concern'

module Arbitrager
  module Balances
    class BtcBox
      include Arbitrager::Balances::Concern

      attr_accessor :jpy, :btc
      attr_reader :broker, :client

      CODE = :btcbox
      CURRENCY_CODE_JPY = 'jpy_balance'
      CURRENCY_CODE_BTC = 'btc_balance'

      def initialize
        @broker = Arbitrager.brokers.btcbox
        @client = Arbitrager.clients.btcbox
        @threshold_jpy = Settings.balancer.threshold.jpy
        @threshold_btc = Settings.balancer.threshold.btc
      end

      # 資産状況の更新を行う
      #
      # @return [true, false] 資産状況の更新に成功した場合 true
      def refresh
        response = client.get_balance

        return false unless response.valid?

        balances = response.params
        @jpy = balances[CURRENCY_CODE_JPY].to_f
        @btc = balances[CURRENCY_CODE_BTC].to_f


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
