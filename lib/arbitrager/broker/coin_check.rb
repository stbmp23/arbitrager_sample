# frozen_string_literal: true

module Arbitrager
  module Broker
    class CoinCheck
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.coincheck
        @account = Arbitrager.config[:account]['coincheck']
      end
    end
  end
end
