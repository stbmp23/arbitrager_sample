# frozen_string_literal: true

module Arbitrager
  module Balances
    module Concern
      # 資産状況を成功するまで行う
      #
      # @return [true, false]
      def refresh!
        Arbitrager.logger.info("Balancer: #{self.class} の資産状況の更新を行います")

        start_time = Time.now
        until refresh
          Arbitrager.logger.warn("Balancer: #{self.class} の資産状況の更新に失敗しました。#{Settings.balancer.wait_for_refresh}秒後にもう一度実行します。")
          return false if Time.now - start_time >= Settings.balancer.check_wait_time
          sleep Settings.balancer.wait_for_refresh
        end

        true
      end

      # 資産の偏りがあるかどうか
      #
      # @return [true, false] 偏りがある場合は true
      def ok?
        return false if @jpy < @threshold_jpy
        return false if @btc < @threshold_btc

        true
      end
    end
  end
end
