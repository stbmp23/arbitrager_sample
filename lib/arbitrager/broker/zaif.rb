# frozen_string_literal: true

module Arbitrager
  module Broker
    class Zaif
      include Arbitrager::Broker

      def initialize
        @config = Settings.broker.zaif
        @account = Arbitrager.config[:account]['zaif']
      end
    end
  end
end
