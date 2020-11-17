# frozen_string_literal: true

module Arbitrager
  module Broker
    class Quoinex
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.quoinex
        @account = Arbitrager.config[:account]['quoinex']
      end
    end
  end
end
