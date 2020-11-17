# frozen_string_literal: true

module Arbitrager
  module Broker
    class BtcBox
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.btcbox
        @account = Arbitrager.config[:account]['btcbox']
      end
    end
  end
end
