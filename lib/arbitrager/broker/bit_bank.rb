# frozen_string_literal: true

module Arbitrager
  module Broker
    class BitBank
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.bitbank
        @account = Arbitrager.config[:account]['bitbank']
      end
    end
  end
end
