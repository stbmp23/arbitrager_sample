# frozen_string_literal: true

module Arbitrager
  module Api
    module Validator
      class BtcBox
        RESPONSE_SUCCESS = 1

        attr_reader :method_code

        # initialize
        #
        # @param [Symbol] method_code APIの実行メソッド名
        def initialize(method_code = nil)
          @method_code = method_code
        end

        # APIの実行メソッドからバリデーションを実行する
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def valid?(params)
          send(:"#{method_code}_response", params)
        end

        # 板情報レスポンス
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def order_books_response(params)
          params['asks'].present? && params['bids'].present?
        end

        # 注文作成時のレスポンス
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def send_order_response(params)
          response_success?(:send_order, params)
        end

        # 注文一覧レスポンス
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def get_orders_response(params)
          unless params.is_a?(Array)
            error(:get_orders, params)
          else
            true
          end
        end

        # 注文を1件取得する
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def get_order_response(params)
          if params['id'].blank?
            error(:get_order, params)
          else
            true
          end
        end

        # 注文をキャンセルする
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def cancel_order_response(params)
          if params['result'].blank?
            error(:cancel_order, params)
          else
            true
          end
        end

        # 総資産レスポンス
        #
        # @params [Hash, Array] JSON.parse(response.body) の結果
        # @return [true, false]
        def get_balance_response(params)
          if params['jpy_balance'].present? && params['btc_balance'].present?
            true
          else
            error(:get_balance, params)
          end
        end

        private

        # レスポンスが成功しているものかどうか
        #
        # @param [Symbol] method_name メソッド名
        # @params [Hash, Array, nil] params JSON.parse(response.body)
        # @return [true, false]
        def response_success?(method_name, params)
          if params['result'].blank? || params['result'] != true
            error(method_name, params)
          else
            true
          end
        end

        # レスポンスチェックエラーを発生させる
        #
        # @param [Symbol] method_name メソッド名
        # @return [false]
        def error(method_name, params = nil)
          message = "BtcBox.#{method_name} のレスポンスがおかしいです. レスポンス: #{params}"
          Arbitrager.logger.error(nil, message)
          false
        end
      end
    end
  end
end
