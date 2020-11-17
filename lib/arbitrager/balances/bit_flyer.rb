# frozen_string_literal: true

require 'arbitrager/balances/concern'

module Arbitrager
  module Balances
    class BitFlyer
      include Arbitrager::Balances::Concern

      attr_accessor :jpy, :btc
      attr_reader :broker, :client

      CODE = :birflyer
      CURRENCY_CODE_JPY = 'JPY'
      CURRENCY_CODE_BTC = 'BTC'

      def initialize
        @broker = Arbitrager.brokers.bitflyer
        @client = Arbitrager.clients.bitflyer
        @threshold_jpy = Settings.balancer.threshold.jpy
        @threshold_btc = Settings.balancer.threshold.btc
      end

      # 資産状況の更新を行う
      #
      # @return [true, false] 資産状況の更新に成功した場合 true
      def refresh
        response = client.get_balance

        return false unless response.valid?

        response.params.each do |cols|
          amount = cols['amount'].to_f

          case cols['currency_code']
          when CURRENCY_CODE_JPY
            @jpy = amount
          when CURRENCY_CODE_BTC
            @btc = amount
          end
        end

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
