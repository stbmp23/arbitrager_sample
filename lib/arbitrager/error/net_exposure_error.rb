# frozen_string_literal: true

module Arbitrager
  class Error
    class NetExposureError < Error
      def initialize
        max_net_exposure = Settings.max_net_exposure

        message = "ネットエクスポージャーが設定値を超えたためシステムを停止します\n"
        message += "TargetNetExposure: #{Arbitrager.analyzer.target_net_exposure}, 設定値: #{max_net_exposure}\n"

        Arbitrager.logger.fatal(nil, message)

        super
      end
    end
  end
end
