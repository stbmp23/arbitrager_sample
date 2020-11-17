# frozen_string_literal: true

module Arbitrager
  class Error
    class ApiValidationError < Error
      def initialize(params, message = '')
        log = "APIのバリデーションが失敗しました\n"
        log += "送信パラメータ: #{params}\n"
        log += "エラー理由: #{message}\n"
        log += "Exit!\n"

        Arbitrager.logger.fatal(nil, log)

        super()
      end
    end
  end
end
