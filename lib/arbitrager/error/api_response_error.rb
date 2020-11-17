# frozen_string_literal: true

module Arbitrager
  class Error
    class ApiResponseError < Error
      attr_reader :response

      def initialize(path, query, header = nil, res = nil, message = nil)
        @response = res

        log = "APIの実行に失敗しました。"
        log += "API STATUS: #{res.status}\n" if res
        log += "path: #{path}\n"
        log += "送信クエリ: #{query}\n"
        log += "リクエストヘッダ: #{header}\n" if header
        log += "レスポンスBODY: #{res.body}\n\n" if res
        log += "response_message: #{message}\n" if message
        log += caller.join("\n")

        Arbitrager.logger.fatal(nil, log)

        super()
      end
    end
  end
end
