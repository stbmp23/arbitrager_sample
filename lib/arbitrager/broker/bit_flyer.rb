# frozen_string_literal: true

module Arbitrager
  module Broker
    class BitFlyer
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.bitflyer
        @account = Arbitrager.config[:account]['bitflyer']
      end
    end
  end
end
