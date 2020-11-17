# frozen_string_literal: true

module Arbitrager
  module Api
    class Response
      attr_reader :response, :validator, :body, :params

      # initialize
      #
      # @params [HTTP::Message] HTTPClientレスポンス
      # @params [Arbitrager::Api::Validator] バリデータ
      def initialize(response, validator)
        @response = response
        @body = response.body
        @validator = validator
        @params = body != '' ? JSON.parse(body) : nil
      end

      # レスポンスのバリデーション実行
      #
      # @return [true, false]
      def valid?
        validator.valid?(params)
      end
    end
  end
end
